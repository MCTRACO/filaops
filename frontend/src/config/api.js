/**
 * API Configuration
 * 
 * Centralized API URL configuration to avoid IPv6/IPv4 resolution issues.
 * Use 127.0.0.1 instead of localhost for better compatibility.
 */
export const API_URL = import.meta.env.VITE_API_URL || "http://127.0.0.1:8000";

