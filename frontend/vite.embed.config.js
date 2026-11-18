import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  define: {
    'process.env.NODE_ENV': '"production"'
  },
  build: {
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, 'src/embed.jsx'),
      name: 'AskUniWidget',
      formats: ['iife'],
      fileName: () => 'askuni-widget.iife.js'
    }
  }
});