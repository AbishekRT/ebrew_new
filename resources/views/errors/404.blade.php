<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>404 Not Found</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: #ffffff;
            text-align: center;
        }

        h1 {
            font-size: 100px;
            margin-bottom: 10px;
        }

        p {
            font-size: 16px;
            margin-bottom: 30px;
            color: #555;
        }

        .home-button {
            background-color: #2d0d1c;
            color: white;
            padding: 15px 20px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            width: 200px;
            transition: background-color 0.3s;
        }

        .home-button:hover {
            background-color: #4a1a33;
        }
    </style>
</head>

<body>
    <h1>404 Not Found</h1>
    <p>Your visited page not found. You may go home page.</p>

    <!-- This will take user to home.blade.php via "/" route -->
    <a href="{{ url('/') }}">
        <button type="button" class="home-button">Back to home page</button>
    </a>
</body>

