// frontend/lib/error-messages.ts
import axios from "axios";

type ErrorContext =
  | "auth-login"
  | "auth-register"
  | "project-create"
  | "project-delete"
  | "project-update"
  | "project-upload"
  | "video-upload"
  | "video-delete"
  | "video-download"
  | "video-trim"
  | "video-speed"
  | "project-download"
  | "project-process"
  | "project-cancel-process"
  | "project-load"           
  | "billing"
  | "upgrade"
  | "ai"
  | "account-profile"     
  | "account-password" 
  | "generic"
  | "assistant-suggest"
  | "project-reorder";

type ErrorInfo = {
  title: string;
  description: string;
};

export function getErrorMessage(
  context: ErrorContext,
  error?: unknown,
): ErrorInfo {
  // 1) Network errors (no response)
  if (axios.isAxiosError(error) && !error.response) {
    return {
      title: "No internet connection",
      description:
        "Could not communicate with the server. Please check your connection and try again.",
    };
  }

  // 2) Simple backend error message
  const backendMsg =
    axios.isAxiosError(error) && typeof error.response?.data === "string"
      ? error.response?.data
      : undefined;

  if (backendMsg === "No more daily_operations available") {
    return {
      title: "Daily limit reached",
      description:
        "You have reached your daily limit for advanced operations. Try again tomorrow or upgrade to Premium.",
    };
  }

  // 3) Specific contexts
  switch (context) {
    case "video-delete":
    case "video-download": {
      const status = axios.isAxiosError(error) ? error.response?.status : undefined;
      const action = context === "video-delete" ? "delete" : "download";
      if (status === 401) return { title: "Invalid session", description: "Please sign in again." };
      if (status === 403) return { title: "Permission denied", description: `You do not have permission to ${action} this video.` };
      if (status === 404) return { title: "Video not found", description: "The video is no longer associated with this project." };
      if (status === 409) return { title: "Project updated", description: "The project was modified. Data was refreshed; please try again." };
      return { title: `Error attempting to ${action} video`, description: `Could not ${action} the video. Please try again.` };
    }
    case "video-speed": {
      const status = axios.isAxiosError(error) ? error.response?.status : undefined;
      const data = axios.isAxiosError(error) ? error.response?.data : error;
      const code = data && typeof data === "object" && "code" in data ? data.code : undefined;
      if (code === "EMPTY_INTERVALS") return { title: "Missing intervals", description: "Please add at least one interval." };
      if (code === "VIDEO_DURATION_UNAVAILABLE") return { title: "Video unavailable", description: "Could not retrieve video duration. Please close and reopen the tool." };
      if (code === "INVALID_TIME") return { title: "Invalid times", description: "Fill start and end with finite numbers." };
      if (code === "INVALID_TIME_BOUNDS") return { title: "Invalid interval", description: "Start time must be less than end time and cannot be negative." };
      if (code === "INTERVAL_OUT_OF_BOUNDS") return { title: "Interval out of bounds", description: "The interval exceeds the video duration." };
      if (code === "INVALID_SPEED") return { title: "Invalid speed", description: "Select a valid speed: 0.5x, 1x or 2x." };
      if (code === "OVERLAPPING_INTERVALS") return { title: "Overlapping intervals", description: "Intervals cannot overlap." };
      if (code === "INVALID_INTERVALS") return { title: "Invalid intervals", description: "Check times, speeds and overlapping intervals." };
      if (code === "INVALID_VIDEO_NAME") return { title: "Invalid name", description: "Could not assign a valid name to the new video." };
      if (status === 401) return { title: "Invalid session", description: "Please sign in again to change speed." };
      if (status === 403 || code === "ACCESS_FORBIDDEN") return { title: "Permission denied", description: "You do not have permission to edit this project." };
      if (status === 404) return { title: "Video unavailable", description: "The project or video is no longer available." };
      if (status === 409) return { title: "Project updated", description: "Data was refreshed. Please check intervals and try again." };
      if (status === 428) return { title: "Version unavailable", description: "Please refresh the project and try again." };
      return { title: "Submission failed", description: "Could not submit the speed task. Please try again." };
    }
    case "video-trim": {
      const status = axios.isAxiosError(error) ? error.response?.status : undefined;
      const data = axios.isAxiosError(error) ? error.response?.data : undefined;
      const code = data && typeof data === "object" ? data.code : undefined;
      const message = data && typeof data === "object" ? data.message : undefined;
      if (code === "ANONYMOUS_NOT_ALLOWED") return { title: "Registered account required", description: message || "Video processing requires a PictuRAS account. Please create a free account or sign in to continue." };
      if (code === "DAILY_QUOTA_EXCEEDED") return { title: "Daily limit reached", description: message || "You have reached your daily limit of 5 free operations. Upgrade to Premium for unlimited operations or try again tomorrow." };
      if (code === "DURATION_LIMIT_EXCEEDED") return { title: "Duration limit exceeded", description: message || "Snippet duration exceeds the allowed limit for your plan (180s for Free / 60 minutes for Premium)." };
      if (code === "STORAGE_QUOTA_EXCEEDED") return { title: "Storage limit reached", description: message || "Your library has reached your account storage limit (1 GB Free / 5 GB Premium). Delete existing videos or upgrade to Premium." };
      if (code === "INVALID_TIME_BOUNDS") return { title: "Invalid time range", description: message || "The end time must be greater than the start time (minimum 1.0s) and within video duration." };
      if (code === "VIDEO_NAME_EXISTS") return { title: "Name already exists", description: "A video with this name already exists in the project. Please choose another name." };
      if (status === 401) return { title: "Invalid session", description: "Please sign in again to trim the video." };
      if (status === 403) return { title: "Permission denied", description: message || "You do not have permission to trim this video." };
      if (status === 409) return { title: "Project updated", description: "The project was modified. Data was refreshed; please try again." };
      return { title: "Error trimming video", description: message || "Could not submit the trim task. Please try again." };
    }
    case "video-upload": {
      const status = axios.isAxiosError(error) ? error.response?.status : undefined;
      const data = axios.isAxiosError(error) ? error.response?.data : undefined;
      const code = data && typeof data === "object" ? data.code : undefined;
      if (code === "VIDEO_NAME_EXISTS") return { title: "Name already used", description: "A video with this name already exists in the project. Please rename the file and try again." };
      if (code === "PROJECT_CONFLICT") return { title: "Project updated", description: "The project was modified. Data was refreshed; please confirm the file and try again." };
      if (status === 401) return { title: "Invalid session", description: "Please sign in again to upload the video." };
      if (status === 403) return { title: "Permission denied", description: "You do not have permission or a valid plan to upload videos to this project." };
      if (status === 404) return { title: "Project not found", description: "The project is no longer available." };
      if (status === 413) return { title: "Video too large", description: "The video exceeds your plan limit: 1 GB Free or 5 GB Premium." };
      if (status === 415) return { title: "Invalid video", description: "The file must be an MP4 video with H.264 codec." };
      if (status === 400) return { title: "Invalid file", description: "Please select a single valid MP4 file." };
      if (status === 428) return { title: "Version unavailable", description: "Please refresh the project and try again." };
      if (error instanceof Error && !axios.isAxiosError(error)) return { title: "Video too large", description: error.message };
      return { title: "Error uploading video", description: "Could not save the video. Please try again." };
    }
    case "auth-login":
      return {
        title: "Login error",
        description:
          backendMsg ??
          "Unable to sign in. Please verify your credentials and try again.",
      };

    case "auth-register":
      return {
        title: "Registration error",
        description:
          backendMsg ??
          "Unable to complete registration. Please verify your details and try again.",
      };

    case "project-create":
      return {
        title: "Error creating project",
        description:
          backendMsg ??
          "A problem occurred while creating the project. Please check your connection and try again.",
      };

    case "project-upload":
      return {
        title: "Error uploading images",
        description:
          backendMsg ??
          "Images could not be uploaded. Check file formats and sizes and try again.",
      };

    case "project-download":
      return {
        title: "Download error",
        description:
          backendMsg ??
          "Could not download the project. Please try again later.",
      };

    case "project-process":
      return {
        title: "Processing failure",
        description:
          backendMsg ??
          "An error occurred while processing the project. Please try again.",
      };

    case "project-cancel-process":
      return {
        title: "Could not cancel processing",
        description:
          backendMsg ??
          "Cancelling the process failed. Please check your connection and try again.",
      };

    case "account-profile":
      return {
        title: "Error updating profile",
        description:
          backendMsg ??
          "Could not update profile details. Check your information and try again.",
      };

    case "account-password":
      return {
        title: "Error updating password",
        description:
          backendMsg ??
          "Could not update password. Confirm your current password and try again.",
      };

    case "upgrade":
      return {
        title: "Error upgrading plan",
        description:
          backendMsg ??
          "An error occurred while changing subscription plan. Please try again.",
      };
    
    case "billing":
      return {
        title: "Billing error",
        description:
          backendMsg ??
          "An error occurred while managing your subscription or payment method.",
      };

    case "ai":
      return {
        title: "AI failure",
        description:
          backendMsg ??
          "Could not generate AI suggestions. Please try again.",
      };

    case "project-load":
      return {
        title: "Error loading project",
        description:
          backendMsg ??
          "Could not load the project. Please check your connection and try again.",
      };

    case "assistant-suggest":
      return {
        title: "Processing failure",
        description: "Processing failed. Please try again.",
      };

    case "project-reorder":
      return {
        title: "Error applying suggestion",
        description:
          backendMsg ??
          "Could not update tool sequence. Please try again.",
      };

    default:
      return {
        title: "An error occurred",
        description:
          backendMsg ??
          "Something went wrong. Please try again later.",
      };
  }
}

export function getAiErrorMessage(
  code?: number,
  backendMsg?: string,
): ErrorInfo {
  if (code != null) {
    switch (code) {
      case 1100:
      case 1101:
        return {
          title: "Background removal error",
          description:
            "Could not remove background from this image. Please try again or use another image.",
        };

      case 1800:
      case 1801:
        return {
          title: "Image upscale error",
          description:
            "Could not upscale this image. Check format and size and try again.",
        };

      case 2000:
      case 2001:
        return {
          title: "Smart crop error",
          description:
            "Could not compute smart crop for this image. Please try again or adjust the original image.",
        };

      case 2100:
      case 2101:
        return {
          title: "Object detection error",
          description:
            "Could not detect objects in the image. Please try again or use an image with higher contrast.",
        };
    }
  }

  return {
    title: "AI error",
    description:
      backendMsg ??
      "Could not apply AI tool. Please check your connection and try again later.",
  };
}
