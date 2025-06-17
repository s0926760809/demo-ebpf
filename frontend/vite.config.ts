import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import { visualizer } from 'rollup-plugin-visualizer';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react({
      // 優化JSX處理
      jsxRuntime: 'automatic'
    }),
    visualizer({
      open: true, // 在預設瀏覽器中自動開啟報告
      gzipSize: true, // 顯示 gzip 後的大小
      brotliSize: true, // 顯示 brotli 後的大小
      filename: 'dist/stats.html', // 產出報告的位置
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      'react': path.resolve('./node_modules/react'),
      'react-dom': path.resolve('./node_modules/react-dom'),
      // 添加額外的路徑別名以提高開發體驗
      'react/jsx-runtime': path.resolve('./node_modules/react/jsx-runtime'),
      'react/jsx-dev-runtime': path.resolve('./node_modules/react/jsx-dev-runtime')
    },
    dedupe: ['react', 'react-dom']
  },
  server: {
    host: '0.0.0.0',
    port: 3000,
    strictPort: true,
    // 代理後端API請求
    proxy: {
      '/api/v1': {
        target: 'http://localhost:30080',
        changeOrigin: true,
        secure: false,
        configure: (proxy, _options) => {
          proxy.on('error', (err, _req, _res) => {
            console.log('proxy error', err);
          });
          proxy.on('proxyReq', (proxyReq, req, _res) => {
            console.log('Sending Request to the Target:', req.method, req.url);
          });
          proxy.on('proxyRes', (proxyRes, req, _res) => {
            console.log('Received Response from the Target:', proxyRes.statusCode, req.url);
          });
        },
      },
      '/api/trading': {
        target: 'http://localhost:30080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/trading/, '/api/v1')
      },
      '/api/risk': {
        target: 'http://localhost:30081',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/risk/, '')
      },
      '/api/payment': {
        target: 'http://localhost:30082',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/payment/, '')
      },
      '/api/audit': {
        target: 'http://localhost:30083',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/audit/, '')
      },
      // WebSocket代理
      '/ws': {
        target: 'ws://localhost:30083',
        ws: true,
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    // 優化打包
    rollupOptions: {
      external: [],
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'antd-vendor': ['antd', '@ant-design/icons'],
          'charts-vendor': ['recharts', 'chart.js', 'react-chartjs-2'],
          'monaco-vendor': ['monaco-editor', '@monaco-editor/react'],
          'utils-vendor': ['lodash', 'dayjs', 'uuid', 'axios']
        },
        // 改善輸出文件名規則
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      },
    },
    // 故意保留一些調試信息用於演示
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: false, // 故意不移除console.log
        drop_debugger: false, // 故意不移除debugger
      },
      mangle: {
        keep_fnames: true, // 保留函數名用於調試
      },
    },
    // 增加構建性能配置
    chunkSizeWarningLimit: 1000,
    assetsInlineLimit: 4096
  },
  define: {
    'process.env': JSON.stringify({}),
    global: 'globalThis',
    // 故意暴露一些環境信息用於安全演示
    __DEV_MODE__: JSON.stringify(process.env.NODE_ENV === 'development'),
    __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
    __APP_VERSION__: JSON.stringify('3.7.0'),
    // 添加額外的環境變量定義
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    'import.meta.env.VITE_APP_VERSION': JSON.stringify('3.7.0')
  },
  // 🔥 v3.7 關鍵修復：開發時的依賴優化
  optimizeDeps: {
    force: true, // 強制重新預構建依賴
    include: [
      'react',
      'react-dom',
      'react/jsx-runtime',
      'react/jsx-dev-runtime',
      'antd',
      '@ant-design/icons',
      'socket.io-client',
      'axios',
      'lodash',
      'dayjs',
      'react-router-dom',
      'zustand',
      'react-hook-form'
    ],
    exclude: [],
    // 添加預構建選項
    esbuildOptions: {
      define: {
        global: 'globalThis'
      }
    }
  },
  css: {
    preprocessorOptions: {
      less: {
        javascriptEnabled: true,
      },
    },
    // 添加CSS後處理選項
    postcss: {
      plugins: []
    }
  },
  // 添加性能監控
  logLevel: 'info',
  clearScreen: false
}) 