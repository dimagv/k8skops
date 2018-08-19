package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"runtime"
	"syscall"

	k8s_client "k8s.io/client-go/tools/clientcmd"
	k8s_api "k8s.io/client-go/tools/clientcmd/api"

	"github.com/spf13/cobra"
	"golang.org/x/oauth2"
)

const (
	appState = "login"
)

type app struct {
	clientID     string
	clientSecret string
	redirectURI  string
	kubeconfig   string
	kubecluster  string

	verifier *oidc.IDTokenVerifier
	provider *oidc.Provider

	client       *http.Client
	shutdownChan chan bool
}

type claim struct {
	Iss           string `json:"iss"`
	Sub           string `json:"sub"`
	Aud           string `json:"aud"`
	Exp           int    `json:"exp"`
	Iat           int    `json:"iat"`
	AtHash        string `json:"at_hash"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`
}

func cmd() *cobra.Command {
	var (
		a         app
		issuerURL string
		listen    string
	)

	c := cobra.Command{
		Use:   "k8s-auth",
		Short: "Authenticates users against OIDC and writes the required kubeconfig.",
		Long:  "",
		RunE: func(cmd *cobra.Command, args []string) error {
			u, err := url.Parse(a.redirectURI)
			if err != nil {
				return fmt.Errorf("parse redirect-uri: %v", err)
			}

			listenURL, err := url.Parse(listen)
			if err != nil {
				return fmt.Errorf("parse listen address: %v", err)
			}

			a.client = http.DefaultClient

			ctx := oidc.ClientContext(context.Background(), a.client)
			provider, err := oidc.NewProvider(ctx, issuerURL)
			if err != nil {
				return fmt.Errorf("Failed to query provider %q: %v", issuerURL, err)
			}

			a.provider = provider
			a.verifier = provider.Verifier(&oidc.Config{ClientID: a.clientID})
			a.shutdownChan = make(chan bool)

			http.HandleFunc("/", a.handleLogin)
			http.HandleFunc(u.Path, a.handleCallback)

			switch listenURL.Scheme {
			case "http":
				log.Printf("listening on %s", listen)
				go open(listen)
				go a.waitShutdown()
				return http.ListenAndServe(listenURL.Host, nil)
			default:
				return fmt.Errorf("listen address %q is not using http", listen)
			}
		},
	}

	c.Flags().StringVar(&a.clientID, "client-id", "", "OAuth2 client ID of this application.")
	c.Flags().StringVar(&a.clientSecret, "client-secret", "", "OAuth2 client secret of this application.")
	c.Flags().StringVar(&a.redirectURI, "redirect-uri", "http://127.0.0.1:5555/callback", "Callback URL for OAuth2 responses.")
	c.Flags().StringVar(&issuerURL, "issuer", "https://dex.example.com", "URL of the OpenID Connect issuer.")
	c.Flags().StringVar(&listen, "listen", "http://127.0.0.1:5555", "HTTP(S) address to listen at.")
	c.Flags().StringVar(&a.kubeconfig, "kubeconfig", "config", "Kubeconfig file to configure")
	c.Flags().StringVar(&a.kubecluster, "kubecluster", "https://api.insurancetruck.example.com", "K8s cluster URL")
	return &c
}

func main() {
	if err := cmd().Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(2)
	}
}

func (a *app) handleLogin(w http.ResponseWriter, r *http.Request) {
	scopes := []string{"openid", "offline_access", "profile"}
	authCodeURL := a.oauth2Config(scopes).AuthCodeURL(appState, oauth2.AccessTypeOffline)
	http.Redirect(w, r, authCodeURL, http.StatusSeeOther)
}

func (a *app) handleCallback(w http.ResponseWriter, r *http.Request) {
	var (
		err   error
		token *oauth2.Token
	)

	ctx := oidc.ClientContext(r.Context(), a.client)
	oauth2Config := a.oauth2Config(nil)

	// Authorization redirect callback from OAuth2 auth flow.
	if errMsg := r.FormValue("error"); errMsg != "" {
		http.Error(w, errMsg+": "+r.FormValue("error_description"), http.StatusBadRequest)
		return
	}

	code := r.FormValue("code")
	if code == "" {
		http.Error(w, fmt.Sprintf("no code in request: %q", r.Form), http.StatusBadRequest)
		return
	}

	if state := r.FormValue("state"); state != appState {
		http.Error(w, fmt.Sprintf("expected state %q got %q", appState, state), http.StatusBadRequest)
		return
	}

	token, err = oauth2Config.Exchange(ctx, code)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to get token: %v", err), http.StatusInternalServerError)
		return
	}

	rawIDToken, ok := token.Extra("id_token").(string)
	if !ok {
		http.Error(w, "no id_token in token response", http.StatusInternalServerError)
		return
	}

	idToken, err := a.verifier.Verify(r.Context(), rawIDToken)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to verify ID token: %v", err), http.StatusInternalServerError)
		return
	}

	var claims json.RawMessage
	idToken.Claims(&claims)

	buff := new(bytes.Buffer)
	json.Indent(buff, []byte(claims), "", "  ")
	var m claim
	err = json.Unmarshal(claims, &m)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to read claims: %v", err), http.StatusInternalServerError)
		go func() {
			a.shutdownChan <- true
		}()
		return
	}

	err = updateKubeConfig(rawIDToken, token.RefreshToken, m, a)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to update kubeconfig: %v", err), http.StatusInternalServerError)
		go func() {
			a.shutdownChan <- true
		}()
		return
	}

	err = renderToken(w, a.redirectURI, rawIDToken, token.RefreshToken, buff.Bytes(), true)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to render token: %v", err), http.StatusInternalServerError)
		go func() {
			a.shutdownChan <- true
		}()
		return
	}

	fmt.Printf("Login Succeeded as %s\n", m.Name)
	if len(a.kubeconfig) > 0 {
		fmt.Printf("kubectl --kubeconfig=%s config use-context %s\n", a.kubeconfig, m.Name)
	} else {
		fmt.Printf("kubectl config use-context %s\n", m.Name)
	}

	go func() {
		a.shutdownChan <- true
	}()
}

func updateKubeConfig(IDToken string, refreshToken string, claims claim, a *app) error {
	var config *k8s_api.Config
	var outputFilename string
	var err error

	clientConfigLoadingRules := k8s_client.NewDefaultClientConfigLoadingRules()

	if a.kubeconfig != "" {
		if _, err = os.Stat(a.kubeconfig); os.IsNotExist(err) {
			config = k8s_api.NewConfig()
			err = nil
		} else {
			clientConfigLoadingRules.ExplicitPath = a.kubeconfig
			config, err = clientConfigLoadingRules.Load()
		}
		outputFilename = a.kubeconfig
	} else {
		config, err = clientConfigLoadingRules.Load()
		outputFilename = k8s_client.RecommendedHomeFile
		if !k8s_api.IsConfigEmpty(config) {
			outputFilename = clientConfigLoadingRules.GetDefaultFilename()
		}
	}
	if err != nil {
		return err
	}

	// set auth-info
	authInfo := k8s_api.NewAuthInfo()
	if conf, ok := config.AuthInfos[claims.Name]; ok {
		authInfo = conf
	}

	authInfo.AuthProvider = &k8s_api.AuthProviderConfig{
		Name: "oidc",
		Config: map[string]string{
			"client-id":      a.clientID,
			"client-secret":  a.clientSecret,
			"id-token":       IDToken,
			"refresh-token":  refreshToken,
			"idp-issuer-url": claims.Iss,
		},
	}

	config.AuthInfos[claims.Name] = authInfo

	// set cluster
	cluster := k8s_api.NewCluster()
	if conf, ok := config.Clusters[a.kubecluster]; ok {
		cluster = conf
	}
	cluster.Server = a.kubecluster
	cluster.InsecureSkipTLSVerify = true
	config.Clusters[a.kubecluster] = cluster

	// set context
	context := k8s_api.NewContext()
	if conf, ok := config.Contexts[claims.Name]; ok {
		context = conf
	}
	context.Cluster = a.kubecluster
	context.AuthInfo = claims.Name
	config.Contexts[claims.Name] = context

	fmt.Printf("Writing config to %s\n", outputFilename)
	err = k8s_client.WriteToFile(*config, outputFilename)
	if err != nil {
		return err
	}
	return nil
}

func open(url string) error {
	var cmd string
	var args []string

	switch runtime.GOOS {
	case "windows":
		cmd = "cmd"
		args = []string{"/c", "start"}
	case "darwin":
		cmd = "open"
	default: // "linux", "freebsd", "openbsd", "netbsd"
		cmd = "xdg-open"
	}
	args = append(args, url)
	return exec.Command(cmd, args...).Start()
}

func (a *app) oauth2Config(scopes []string) *oauth2.Config {
	return &oauth2.Config{
		ClientID:     a.clientID,
		ClientSecret: a.clientSecret,
		Endpoint:     a.provider.Endpoint(),
		Scopes:       scopes,
		RedirectURL:  a.redirectURI,
	}
}

func (a *app) waitShutdown() {
	irqSig := make(chan os.Signal, 1)
	signal.Notify(irqSig, syscall.SIGINT, syscall.SIGTERM)

	//Wait interrupt or shutdown request through /shutdown
	select {
	case sig := <-irqSig:
		log.Printf("Shutdown request (signal: %v)", sig)
		os.Exit(0)
	case <-a.shutdownChan:
		os.Exit(0)
	}
}
