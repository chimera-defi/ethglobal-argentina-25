'use client';

import { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle2, XCircle, AlertCircle, X, Loader2 } from 'lucide-react';

export type ToastType = 'success' | 'error' | 'warning' | 'info' | 'loading';

export interface Toast {
  id: string;
  message: string;
  type: ToastType;
  duration?: number;
}

interface ToastProps {
  toast: Toast;
  onClose: (id: string) => void;
}

const icons = {
  success: CheckCircle2,
  error: XCircle,
  warning: AlertCircle,
  info: AlertCircle,
  loading: Loader2,
};

const colors = {
  success: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-800 dark:text-green-300',
  error: 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-800 dark:text-red-300',
  warning: 'bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800 text-yellow-800 dark:text-yellow-300',
  info: 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-800 dark:text-blue-300',
  loading: 'bg-gray-50 dark:bg-gray-900/20 border-gray-200 dark:border-gray-800 text-gray-800 dark:text-gray-300',
};

export function Toast({ toast, onClose }: ToastProps) {
  const Icon = icons[toast.type];
  const colorClass = colors[toast.type];

  useEffect(() => {
    if (toast.type !== 'loading' && toast.duration !== 0) {
      const timer = setTimeout(() => {
        onClose(toast.id);
      }, toast.duration || 5000);

      return () => clearTimeout(timer);
    }
  }, [toast.id, toast.duration, toast.type, onClose]);

  return (
    <motion.div
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95, transition: { duration: 0.2 } }}
      className={`flex items-center gap-3 rounded-xl border p-4 shadow-lg backdrop-blur-sm min-w-[300px] max-w-md ${colorClass}`}
    >
      <Icon
        className={`h-5 w-5 flex-shrink-0 ${
          toast.type === 'loading' ? 'animate-spin' : ''
        }`}
      />
      <p className="flex-1 text-sm font-medium">{toast.message}</p>
      {toast.type !== 'loading' && (
        <button
          onClick={() => onClose(toast.id)}
          className="flex-shrink-0 rounded-lg p-1 hover:bg-black/5 dark:hover:bg-white/5 transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
      )}
    </motion.div>
  );
}

interface ToastContainerProps {
  toasts: Toast[];
  onClose: (id: string) => void;
}

export function ToastContainer({ toasts, onClose }: ToastContainerProps) {
  return (
    <div className="fixed top-4 right-4 z-50 flex flex-col gap-2 pointer-events-none">
      <AnimatePresence>
        {toasts.map((toast) => (
          <div key={toast.id} className="pointer-events-auto">
            <Toast toast={toast} onClose={onClose} />
          </div>
        ))}
      </AnimatePresence>
    </div>
  );
}
