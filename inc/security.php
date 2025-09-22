<?php
declare(strict_types=1);

if (!function_exists('e')) {
    /**
     * Escape HTML output using UTF-8 and substitute invalid codepoints.
     */
    function e(?string $value): string
    {
        return htmlspecialchars($value ?? '', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }
}

if (!function_exists('sanitize_class_token')) {
    /**
     * Convert arbitrary text into a safe CSS class token.
     */
    function sanitize_class_token($value, string $prefix = ''): string
    {
        if (!is_scalar($value)) {
            $value = '';
        }

        $token = strtolower((string) $value);
        $token = preg_replace('/[^a-z0-9]+/i', '-', $token);
        if ($token === null) {
            $token = '';
        }
        $token = trim($token, '-');

        if ($token === '') {
            $token = 'desconhecido';
        }

        return $prefix . $token;
    }
}
