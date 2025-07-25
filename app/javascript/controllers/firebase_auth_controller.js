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
  browserSessionPersistence,
  sendEmailVerification,
  applyActionCode
} from "firebase/auth"

// Connects to data-controller="firebase-auth"
export default class extends Controller {
  static values = { 
    config: Object,
    redirectUrl: String,
    enabledProviders: Array
  }
  
  static targets = ["email", "password", "confirmPassword", "error", "info", "submitButton"]

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
    this.clearInfo()

    try {
      console.log("Attempting Firebase sign in...")
      const userCredential = await signInWithEmailAndPassword(this.auth, email, password)
      console.log("Firebase sign in successful")
      
      // Check if email is verified
      if (!userCredential.user.emailVerified) {
        this.showError("Please verify your email address before signing in. Check your inbox for the verification link.")
        await signOut(this.auth) // Sign out unverified user
        return
      }
      
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
    this.clearInfo()

    try {
      console.log("Attempting Firebase sign up...")
      const userCredential = await createUserWithEmailAndPassword(this.auth, email, password)
      console.log("Firebase sign up successful")
      
      // Send email verification
      await sendEmailVerification(userCredential.user)
      console.log("Email verification sent")
      
      this.showInfo("Please check your email and verify your account before signing in.")
      
      // Don't automatically sign in - wait for email verification
      return
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
    this.clearInfo()
    
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
    
    // Always clear browser storage first
    this.clearAllStorage()
    
    // Try Firebase logout if client is available, but don't block on failure
    if (this.auth) {
      signOut(this.auth)
        .then(() => {
          console.log("Firebase sign out successful")
          // The server-side sign out will be handled by the form submission
        })
        .catch((error) => {
          console.log("Firebase sign out failed (but continuing):", error)
          // Continue with backend logout regardless
        })
    }
    
    // Always proceed with backend logout regardless of Firebase client state
    this.performBackendLogout()
  }

  // Clear all browser storage
  clearAllStorage() {
    console.log("Clearing all browser storage...")
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
  }

  // Perform backend logout
  performBackendLogout() {
    fetch('/sign_out', {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(() => {
      console.log("Backend logout successful")
      window.location.href = '/'
    })
    .catch((error) => {
      console.log("Backend logout failed, redirecting anyway:", error)
      // Even if backend fails, redirect anyway since we cleared storage
      window.location.href = '/'
    })
  }

  // Delete user account (requires active Firebase session)
  async deleteAccount(event) {
    if (event) event.preventDefault()
    
    // Check if Firebase user is currently signed in
    if (!this.auth.currentUser) {
      alert('For security, please sign in again to delete your account.')
      window.location.href = '/sign_in'
      return
    }
    
    // Double confirmation for account deletion
    if (!confirm('Are you sure you want to permanently delete your account? This cannot be undone.')) {
      return
    }
    
    if (!confirm('This will delete ALL your data including tasks, participants, and households. Are you absolutely sure?')) {
      return
    }
    
    this.setLoading(true)
    
    try {
      console.log("Starting account deletion process...")
      
      // Step 1: Delete Firebase user account first
      console.log("Deleting Firebase user account...")
      await this.auth.currentUser.delete()
      console.log("Firebase account deleted successfully")
      
      // Step 2: Delete Rails application data
      console.log("Deleting Rails application data...")
      const response = await fetch('/auth/delete_account', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        console.log("Rails data deleted successfully")
        
        // Step 3: Clear all browser storage
        this.clearAllStorage()
        
        // Redirect to home with success message
        alert('Account deleted successfully')
        window.location.href = '/'
      } else {
        throw new Error(data.error || 'Failed to delete Rails data')
      }
      
    } catch (error) {
      console.error("Account deletion failed:", error)
      
      // Handle specific Firebase errors
      if (error.code === 'auth/requires-recent-login') {
        alert('For security, please sign out and sign in again, then try deleting your account.')
        window.location.href = '/sign_out'
      } else if (error.code === 'auth/user-not-found') {
        // Firebase user already deleted, just delete Rails data
        console.log("Firebase user already deleted, cleaning up Rails data...")
        try {
          const response = await fetch('/auth/delete_account', {
            method: 'DELETE',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            }
          })
          const data = await response.json()
          if (data.success) {
            this.clearAllStorage()
            alert('Account deleted successfully')
            window.location.href = '/'
          } else {
            throw new Error('Failed to clean up Rails data')
          }
        } catch (cleanupError) {
          console.error("Cleanup failed:", cleanupError)
          alert('Account deletion encountered errors. Please contact support.')
        }
      } else {
        alert('Failed to delete account: ' + (error.message || 'Unknown error'))
      }
    } finally {
      this.setLoading(false)
    }
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
    this.clearInfo() // Clear info when showing error
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    } else {
      alert(message) // Fallback
    }
  }

  showInfo(message) {
    this.clearError() // Clear error when showing info
    if (this.hasInfoTarget) {
      this.infoTarget.textContent = message
      this.infoTarget.classList.remove("hidden")
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

  clearInfo() {
    if (this.hasInfoTarget) {
      this.infoTarget.textContent = ""
      this.infoTarget.classList.add("hidden")
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