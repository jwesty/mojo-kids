class MojoApp {
    constructor() {
        console.log('Initializing MojoApp...');
        this.token = localStorage.getItem('token');
        this.apiBaseUrl = config.apiBaseUrl;
        this.init();
    }

    init() {
        // Initialize event listeners based on page
        if (document.getElementById('registerForm')) {
            this.initializeRegistration();
        }
        if (document.getElementById('loginForm')) {
            this.initializeLogin();
        }
    }

    initializeLogin() {
        console.log('Initializing login form...');
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const errorMessage = document.getElementById('errorMessage');
            errorMessage.style.display = 'none';

            try {
                const response = await fetch(`${this.apiBaseUrl}/login`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        email: document.getElementById('email').value,
                        password: document.getElementById('password').value
                    })
                });

                const data = await response.json();

                if (response.ok) {
                    // Store token and user data
                    localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data.user));

                    // Check if user is admin
                    if (data.user.isAdmin) {
                        window.location.href = '/admin';
                    } else {
                        window.location.href = '/';
                    }
                } else {
                    errorMessage.textContent = data.message || 'Login failed';
                    errorMessage.style.display = 'block';
                }
            } catch (error) {
                console.error('Login error:', error);
                errorMessage.textContent = 'An error occurred. Please try again.';
                errorMessage.style.display = 'block';
            }
        });
    }

    initializeRegistration() {
        // ... existing registration code ...
    }

    // Helper methods
    async checkAuth() {
        if (!this.token) {
            return false;
        }

        try {
            const response = await fetch(`${this.apiBaseUrl}/verify`, {
                headers: {
                    'Authorization': `Bearer ${this.token}`
                }
            });
            return response.ok;
        } catch (error) {
            console.error('Auth check error:', error);
            return false;
        }
    }

    logout() {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/login';
    }
}

// Initialize when the DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, creating MojoApp instance...');
    window.mojoApp = new MojoApp();
});

// Log any errors
window.addEventListener('error', (event) => {
    console.error('Script error:', event.error);
});