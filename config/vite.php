<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Entrypoints
    |--------------------------------------------------------------------------
    |
    | The files in the configured directories will be considered
    | entrypoints and will not be required in the configuration file.
    | To disable the behavior, set to false or remove.
    |
    */

    'entrypoints' => [
        'paths' => [
            'resources/css',
            'resources/js',
        ],
        'ignore' => '/\\.(d\\.ts|json)$/',
    ],

    /*
    |--------------------------------------------------------------------------
    | Aliases
    |--------------------------------------------------------------------------
    |
    | These aliases will be added to the Vite configuration and used
    | to generate a proper manifest file.
    |
    */

    'aliases' => [],

    /*
    |--------------------------------------------------------------------------
    | Ping Timeout
    |--------------------------------------------------------------------------
    |
    | The maximum time, in seconds, that Laravel should wait when pinging
    | the Vite development server to determine if it's running.
    |
    */

    'ping_timeout' => 1,

    /*
    |--------------------------------------------------------------------------
    | Build Path
    |--------------------------------------------------------------------------
    |
    | The path where Vite will output the built assets. This should be
    | relative to the public path.
    |
    */

    'build_path' => 'build',

    /*
    |--------------------------------------------------------------------------
    | Manifest Filename
    |--------------------------------------------------------------------------
    |
    | The filename of the manifest file that Vite will generate.
    |
    */

    'manifest' => 'manifest.json',

    /*
    |--------------------------------------------------------------------------
    | Hot File
    |--------------------------------------------------------------------------
    |
    | The filename of the "hot" file that Vite will generate when the
    | development server is running.
    |
    */

    'hot_file' => 'hot',

    /*
    |--------------------------------------------------------------------------
    | Commands
    |--------------------------------------------------------------------------
    |
    | Commands that can be used to start the Vite development server.
    | Artisan will use the first available command when attempting to
    | serve your application.
    |
    */

    'commands' => [
        'npm run dev',
        'yarn dev',
    ],

    /*
    |--------------------------------------------------------------------------
    | Environment Variables
    |--------------------------------------------------------------------------
    |
    | Environment variables that should be made available to Vite.
    |
    */

    'environment_variables' => [
        'APP_ENV',
    ],

];