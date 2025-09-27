<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'eBrew Café')</title>
    
    <!-- Temporary inline CSS while Vite assets are being fixed -->
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f8f9fa;
            color: #333;
            line-height: 1.6;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            padding: 0 20px; 
        }
        header { 
            background: #8B4513; 
            color: white; 
            padding: 1rem 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        nav { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
        }
        nav ul { 
            list-style: none; 
            display: flex; 
            gap: 2rem; 
        }
        nav a { 
            color: white; 
            text-decoration: none;
            font-weight: 500;
            transition: color 0.3s ease;
        }
        nav a:hover { color: #ffd700; }
        .logo { 
            font-size: 1.8rem; 
            font-weight: bold; 
            color: #ffd700;
        }
        main { 
            background: white; 
            margin: 2rem auto; 
            padding: 2rem; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1, h2, h3 { 
            color: #8B4513; 
            margin-bottom: 1rem; 
        }
        .btn { 
            background: #8B4513; 
            color: white; 
            padding: 12px 24px; 
            border: none; 
            border-radius: 6px; 
            cursor: pointer; 
            text-decoration: none;
            display: inline-block;
            transition: background-color 0.3s ease;
        }
        .btn:hover { background: #6d3410; }
        .product-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); 
            gap: 2rem; 
            margin: 2rem 0; 
        }
        .product-card { 
            border: 1px solid #e0e0e0; 
            border-radius: 8px; 
            padding: 1.5rem; 
            text-align: center;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .product-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }
        .product-image { 
            max-width: 200px; 
            max-height: 200px; 
            object-fit: cover; 
            border-radius: 6px; 
            margin: 0 auto 1rem;
            display: block;
        }
        .faq-item { 
            margin-bottom: 1.5rem; 
            padding: 1.5rem;
            background: #f8f9fa;
            border-left: 4px solid #8B4513;
            border-radius: 0 6px 6px 0;
        }
        .faq-question { 
            font-weight: bold; 
            color: #8B4513; 
            margin-bottom: 0.5rem;
            font-size: 1.1rem;
        }
        .faq-answer { 
            color: #666; 
            line-height: 1.7;
        }
        footer { 
            background: #333; 
            color: white; 
            text-align: center; 
            padding: 2rem 0; 
            margin-top: 3rem;
        }
        .hero { 
            background: linear-gradient(135deg, #8B4513, #a0522d); 
            color: white; 
            text-align: center; 
            padding: 4rem 2rem;
            margin-bottom: 3rem;
        }
        .hero h1 { 
            color: white; 
            font-size: 3rem; 
            margin-bottom: 1rem; 
        }
        .hero p { 
            font-size: 1.2rem; 
            opacity: 0.9; 
        }
        @media (max-width: 768px) {
            nav ul { flex-direction: column; gap: 1rem; }
            .hero h1 { font-size: 2rem; }
            .container { padding: 0 15px; }
        }
    </style>
</head>
<body>
    @yield('content')
</body>
</html>