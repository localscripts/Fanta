document.addEventListener('DOMContentLoaded', function() {
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');
    
    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', function() {
            this.classList.toggle('active');
            
            if (navLinks.style.display === 'flex') {
                navLinks.style.display = 'none';
            } else {
                navLinks.style.display = 'flex';
                navLinks.style.flexDirection = 'column';
                navLinks.style.position = 'absolute';
                navLinks.style.top = '70px';
                navLinks.style.left = '0';
                navLinks.style.width = '100%';
                navLinks.style.backgroundColor = 'var(--dark-color)';
                navLinks.style.padding = '20px';
                navLinks.style.boxShadow = '0 10px 20px rgba(0, 0, 0, 0.3)';
                navLinks.style.zIndex = '1000';
            }
        });
    }

    const faqItems = document.querySelectorAll('.faq-item');
    if (faqItems.length) {
        faqItems.forEach(item => {
            const question = item.querySelector('.faq-question');
            
            question.addEventListener('click', function() {
                const isActive = item.classList.contains('active');
                
                faqItems.forEach(faqItem => {
                    faqItem.classList.remove('active');
                });
                
                if (!isActive) {
                    item.classList.add('active');
                }
            });
        });
    }

    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 80,
                    behavior: 'smooth'
                });
            }
        });
    });

    const header = document.querySelector('header');

    if (header) {
        window.addEventListener('scroll', function() {
            if (window.scrollY > 50) {
                header.style.padding = '5px 0';
                header.style.boxShadow = '0 5px 20px rgba(0, 0, 0, 0.3)';
            } else {
                header.style.padding = '15px 0';
                header.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.3)';
            }
        });
    }

    const animateOnScroll = function() {
        const elements = document.querySelectorAll('.feature-card, .script-container, .faq-item');
        
        elements.forEach(element => {
            const elementPosition = element.getBoundingClientRect().top;
            const screenPosition = window.innerHeight / 1.3;
            
            if (elementPosition < screenPosition) {
                element.style.opacity = '1';
                element.style.transform = 'translateY(0)';
            }
        });
    };

    window.addEventListener('scroll', animateOnScroll);

    animateOnScroll();

    document.querySelectorAll('.feature-card, .script-container, .faq-item').forEach(element => {
        element.style.opacity = '0';
        element.style.transform = 'translateY(30px)';
        element.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    });

    const modal = document.getElementById('script-modal');
    const getScriptBtn = document.getElementById('get-script-btn');
    const getScriptBtn2 = document.getElementById('get-script-btn2');
    const closeModalBtn = document.querySelector('.modal-close');
    
    function openModal() {
        modal.style.display = 'flex';
        setTimeout(() => {
            modal.style.opacity = '1';
            document.querySelector('.modal-content').style.transform = 'translateY(0)';
        }, 10);
    }
    function closeModal() {
        modal.style.opacity = '0';
        document.querySelector('.modal-content').style.transform = 'translateY(-50px)';
        setTimeout(() => {
            modal.style.display = 'none';
        }, 300);
    }
    if (getScriptBtn) {
        getScriptBtn.addEventListener('click', openModal);
    }
    
    if (getScriptBtn2) {
        getScriptBtn2.addEventListener('click', openModal);
    }
    
    if (closeModalBtn) {
        closeModalBtn.addEventListener('click', closeModal);
    }
    window.addEventListener('click', function(e) {
        if (e.target === modal) {
            closeModal();
        }
    });
    const copyScriptBtn = document.getElementById('copy-script-btn');
    const modalCopyBtn = document.getElementById('modal-copy-btn');
    const scriptText = `--[[

     ⚠️ You need to join this group in order to use this script - Fanta.
     ⚠️ Debes unirte a este grupo para poder usar este script - Fanta.
     ⚠️ Вы должны присоединиться к этой группе, чтобы использовать этот скрипт — Fanta.

     https://roblox.com/communities/35623787
     
]]

loadstring(game:HttpGet('https://fanta.voxlis.net/main.lua'))()`;

    function copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            const originalText = event.target.textContent;
            event.target.textContent = 'Copied!';
            
            setTimeout(() => {
                event.target.textContent = originalText;
            }, 2000);
        }).catch(err => {
            console.error('Failed to copy: ', err);
        });
    }
    if (copyScriptBtn) {
        copyScriptBtn.addEventListener('click', function(event) {
            copyToClipboard(scriptText);
        });
    }
    if (modalCopyBtn) {
        modalCopyBtn.addEventListener('click', function(event) {
            copyToClipboard(scriptText);
        });
    }
    const style = document.createElement('style');
    style.textContent = `
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.8);
            z-index: 2000;
            justify-content: center;
            align-items: center;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        
        .modal-content {
            background-color: var(--card-bg);
            border-radius: var(--border-radius);
            width: 90%;
            max-width: 600px;
            box-shadow: var(--shadow);
            border: 1px solid var(--border-color);
            transform: translateY(-50px);
            transition: transform 0.3s ease;
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .modal-header h3 {
            font-size: 1.3rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .modal-close {
            background: none;
            border: none;
            font-size: 1.5rem;
            color: var(--gray-text);
            cursor: pointer;
            transition: var(--transition);
        }
        
        .modal-close:hover {
            color: var(--primary-color);
        }
        
        .modal-body {
            padding: 20px;
        }
        
        .script-code {
            background-color: #0a0a0a;
            border-radius: var(--border-radius);
            padding: 20px;
            margin-bottom: 20px;
            border: 1px solid var(--border-color);
            overflow-x: auto;
        }
        
        .script-code pre {
            margin: 0;
        }
        
        .script-code code {
            font-family: 'Consolas', 'Monaco', monospace;
            color: #e6e6e6;
            line-height: 1.5;
            font-size: 0.9rem;
        }
        
        .modal-instructions {
            margin-bottom: 20px;
        }
        
        .modal-instructions p {
            margin-bottom: 10px;
            color: var(--gray-text);
        }
        
        .modal-instructions a {
            color: var(--primary-color);
            text-decoration: underline;
        }
        
        .modal-instructions a:hover {
            text-decoration: none;
        }
    `;
    document.head.appendChild(style);
});