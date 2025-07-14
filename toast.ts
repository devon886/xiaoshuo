import { useToast } from "vue-toastification";

const toast = useToast();

export const showSuccessToast = (message: string) => {
  toast.success(message);
};

export const showErrorToast = (message: string) => {
  toast.error(message);
};

export const showInfoToast = (message: string) => {
  toast.info(message);
};

export const showWarningToast = (message: string) => {
  toast.warning(message);
};

export default {
  showSuccessToast,
  showErrorToast,
  showInfoToast,
  showWarningToast
}; 