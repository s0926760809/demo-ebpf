/// <reference types="vite/client" />

// 扩展React类型定义
declare module 'react' {
  namespace React {
    const version: string;
  }
}

// 全局类型声明
declare global {
  interface Window {
    React?: typeof import('react');
    debugApp?: {
      react: typeof import('react');
      version: string;
      checkReact: () => void;
      triggerError: () => void;
      triggerSecurityEvent: () => void;
      getAppConfig: () => any;
    };
    APP_CONFIG?: any;
  }
}

// Vite环境变量类型
interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  readonly VITE_APP_TITLE: string;
  readonly DEV: boolean;
  readonly MODE: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

export {}; 