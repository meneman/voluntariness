import { Controller } from "@hotwired/stimulus"
import { initializeApp } from "firebase/app"
import { 
  getAuth, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signInWithPopup,
  GoogleAuthProvider,
  GithubAuthProvider,
  signOut,
  onAuthStateChanged,
  setPersistence,
  browserSessionPersistence
} from "firebase/auth"

// Connects to data-controller="firebase-auth"
export default class extends Controller {
  static values = { 
    config: Object,
    redirectUrl: String,
    enabledProviders: Array
  }
  
  static targets = ["email", "password", "confirmPassword", "error", "submitButton"]

  async connect() {
    console.log("🔥 Firebase Auth controller connected!")
    console.log("Config value:", this.configValue)
    
    // Add visual indicator that controller is working
    if (this.element) {
      this.element.style.border = "2px solid green"
      setTimeout(() => {
        if (this.element) this.element.style.border = ""
      }, 2000)
    }
    
    try {
      // Validate configuration
      if (!this.configValue || !this.configValue.projectId) {
        throw new Error("Firebase configuration is missing or invalid")
      }
      
      console.log("Initializing Firebase with project:", this.configValue.projectId)
      console.log("Full Firebase config:", this.configValue)
      console.log("API Key:", this.configValue.apiKey ? 'Present' : 'Missing')
      
      // Initialize Firebase
      this.app = initializeApp(this.configValue)
      this.auth = getAuth(this.app)
      
      // Set Firebase persistence to SESSION only (not LOCAL)
      // This prevents Firebase from persisting login across browser sessions
      try {
        await setPersistence(this.auth, browserSessionPersistence)
        console.log("Firebase persistence set to SESSION only")
      } catch (persistenceError) {
        console.warn("Could not set Firebase persistence:", persistenceError)
      }
      
      // Initialize enabled authentication providers
      this.enabledProviders = this.enabledProvidersValue || ['google', 'github']
      console.log('Enabled providers:', this.enabledProviders)
      
      if (this.enabledProviders.includes('google')) {
        this.googleProvider = new GoogleAuthProvider()
        this.googleProvider.addScope('email')
        this.googleProvider.addScope('profile')
      }
      
      if (this.enabledProviders.includes('github')) {
        this.githubProvider = new GithubAuthProvider()
        this.githubProvider.addScope('user:email')
      }
      
      console.log("Firebase initialized successfully")
      
      // Disable app verification for testing in development
      if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        // This helps avoid reCAPTCHA issues during development
        window.recaptchaVerifier = null
        console.log("Disabled reCAPTCHA for development")
      }
      
      // Set up auth state listener
      this.setupAuthStateListener()
      console.log("Auth state listener set up")
      
    } catch (error) {
      console.error("Firebase initialization error:", error)
      console.error("Error details:", error.message, error.stack)
      this.showError("Failed to initialize authentication system. Check console for details.")
    }
  }

  disconnect() {
    if (this.unsubscribe) {
      this.unsubscribe()
    }
  }

  setupAuthStateListener() {
    this.unsubscribe = onAuthStateChanged(this.auth, (user) => {
      if (user) {
        console.log("🔥 Firebase User is signed in:")
        console.log("  Email:", user.email)
        console.log("  UID:", user.uid)
        console.log("  Email verified:", user.emailVerified)
        
        // DEBUG: Show which user this will map to
        console.log("🎯 This Firebase user will be processed by server...")
        // User is signed in, we'll handle token verification
      } else {
        console.log("🚪 Firebase User is signed out")
        
        // DEBUG: Ensure we're really logged out
        console.log("🧹 Checking if browser storage is clean...")
        const hasLocalStorage = localStorage.length > 0
        const hasSessionStorage = sessionStorage.length > 0
        console.log("  LocalStorage items:", localStorage.length)
        console.log("  SessionStorage items:", sessionStorage.length)
        
        if (hasLocalStorage || hasSessionStorage) {
          console.warn("⚠️  Browser storage not clean after logout!")
        }
      }
    })
  }

  // Handle sign in form submission
  async signIn(event) {
    event.preventDefault()
    
    const email = this.emailTarget.value.trim()
    const password = this.passwordTarget.value
    
    if (!email || !password) {
      this.showError("Please enter both email and password")
      return
    }

    this.setLoading(true)
    this.clearError()

    try {
      console.log("Attempting Firebase sign in...")
      const userCredential = await signInWithEmailAndPassword(this.auth, email, password)
      console.log("Firebase sign in successful")
      
      const idToken = await userCredential.user.getIdToken()
      await this.verifyTokenOnServer(idToken)
    } catch (error) {
      console.error("Sign in error:", error)
      this.handleAuthError(error)
    } finally {
      this.setLoading(false)
    }
  }

  // Handle sign up form submission
  async signUp(event) {
    event.preventDefault()
    
    const email = this.emailTarget.value.trim()
    const password = this.passwordTarget.value
    const confirmPassword = this.confirmPasswordTarget?.value

    // Validation
    if (!email || !password) {
      this.showError("Please enter both email and password")
      return
    }

    if (password.length < 6) {
      this.showError("Password must be at least 6 characters long")
      return
    }

    if (confirmPassword && password !== confirmPassword) {
      this.showError("Passwords do not match")
      return
    }

    this.setLoading(true)
    this.clearError()

    try {
      console.log("Attempting Firebase sign up...")
      const userCredential = await createUserWithEmailAndPassword(this.auth, email, password)
      console.log("Firebase sign up successful")
      
      const idToken = await userCredential.user.getIdToken()
      await this.verifyTokenOnServer(idToken)
    } catch (error) {
      console.error("Sign up error:", error)
      this.handleAuthError(error)
    } finally {
      this.setLoading(false)
    }
  }

  // Handle Google sign-in
  async signInWithGoogle(event) {
    if (!this.enabledProviders.includes('google')) {
      console.error('Google provider is not enabled')
      this.showError('Google sign-in is not available')
      return
    }
    await this.signInWithProvider(event, this.googleProvider, 'Google')
  }

  // Handle GitHub sign-in
  async signInWithGithub(event) {
    if (!this.enabledProviders.includes('github')) {
      console.error('GitHub provider is not enabled')
      this.showError('GitHub sign-in is not available')
      return
    }
    await this.signInWithProvider(event, this.githubProvider, 'GitHub')
  }

  // Generic method for provider sign-in
  async signInWithProvider(event, provider, providerName) {
    if (event) event.preventDefault()
    
    this.setLoading(true)
    this.clearError()
    
    try {
      console.log(`Attempting ${providerName} sign in...`)
      const result = await signInWithPopup(this.auth, provider)
      console.log(`${providerName} sign in successful`)
      
      const idToken = await result.user.getIdToken()
      await this.verifyTokenOnServer(idToken)
    } catch (error) {
      console.error(`${providerName} sign in error:`, error)
      this.handleAuthError(error)
    } finally {
      this.setLoading(false)
    }
  }

  // Sign out the user
  signOutUser(event) {
    if (event) event.preventDefault()
    
    signOut(this.auth)
      .then(() => {
        console.log("Firebase sign out successful")
        
        // Clear all local storage and session storage
        localStorage.clear()
        sessionStorage.clear()
        
        // Clear any Firebase persistence
        if (typeof window !== 'undefined') {
          // Clear IndexedDB (Firebase persistence)
          if (window.indexedDB) {
            try {
              const deleteReq = window.indexedDB.deleteDatabase('firebaseLocalStorageDb')
              deleteReq.onsuccess = () => console.log("Firebase IndexedDB cleared")
            } catch (e) {
              console.log("Could not clear Firebase IndexedDB:", e)
            }
          }
        }
        
        console.log("All browser storage cleared")
        // The server-side sign out will be handled by the form submission
      })
      .catch((error) => {
        console.error("Sign out error:", error)
      })
  }

  // Verify token with Rails backend
  verifyTokenOnServer(idToken) {
    console.log("🚀 Sending token to server for verification...")
    
    // DEBUG: Decode token for inspection (client-side only for debugging)
    try {
      const tokenParts = idToken.split('.')
      const payload = JSON.parse(atob(tokenParts[1]))
      console.log("🔍 Token payload preview:")
      console.log("  Email:", payload.email)
      console.log("  UID:", payload.user_id || payload.sub)
      console.log("  Email verified:", payload.email_verified)
    } catch (e) {
      console.log("Could not decode token for preview:", e)
    }
    
    return fetch('/auth/verify_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ id_token: idToken })
    })
    .then(response => {
      console.log("Server response status:", response.status)
      return response.json()
    })
    .then(data => {
      console.log("Server verification response:", data)
      
      if (data.success) {
        console.log("Server verification successful, redirecting...")
        // Redirect to the specified URL or default
        const redirectUrl = data.redirect_url || this.redirectUrlValue || '/pages/home'
        console.log("Redirecting to:", redirectUrl)
        window.location.href = redirectUrl
      } else {
        console.error("Server verification failed:", data.error)
        throw new Error(data.error || 'Server verification failed')
      }
    })
    .catch(error => {
      console.error("Token verification error:", error)
      throw error
    })
  }

  // Handle authentication errors
  handleAuthError(error) {
    let message = "An error occurred during authentication"
    
    // Handle reCAPTCHA-related errors
    if (error.message && error.message.includes('_getRecaptchaConfig')) {
      message = "Authentication system is loading. Please try again in a moment."
      this.showError(message)
      return
    }
    
    switch (error.code) {
      case 'auth/user-not-found':
      case 'auth/wrong-password':
        message = "Invalid email or password"
        break
      case 'auth/email-already-in-use':
        message = "An account with this email already exists"
        break
      case 'auth/weak-password':
        message = "Password is too weak"
        break
      case 'auth/invalid-email':
        message = "Invalid email address"
        break
      case 'auth/too-many-requests':
        message = "Too many failed attempts. Please try again later"
        break
      case 'auth/network-request-failed':
        message = "Network error. Please check your connection and try again."
        break
      case 'auth/popup-closed-by-user':
        message = "Sign-in was cancelled. Please try again."
        break
      case 'auth/popup-blocked':
        message = "Pop-up was blocked by your browser. Please allow pop-ups and try again."
        break
      case 'auth/cancelled-popup-request':
        message = "Sign-in was cancelled. Please try again."
        break
      case 'auth/unauthorized-domain':
        message = "This domain is not authorized for Google sign-in. Please contact support."
        break
      default:
        console.error("Unhandled auth error:", error)
        message = error.message || message
    }
    
    this.showError(message)
  }

  // UI Helper methods
  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    } else {
      alert(message) // Fallback
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }

  setLoading(loading) {
    if (this.hasSubmitButtonTarget) {
      // Store original text when first setting loading state
      if (loading && !this.submitButtonTarget.dataset.originalText) {
        this.submitButtonTarget.dataset.originalText = this.submitButtonTarget.textContent
      }
      
      this.submitButtonTarget.disabled = loading
      this.submitButtonTarget.textContent = loading ? "Please wait..." : this.submitButtonTarget.dataset.originalText
    }
  }
}