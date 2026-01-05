/**
 * Listens for 'api:error' and shows a toast. Central place -> fewer silent failures.
 * Also detects tier limit errors and emits 'tier:limit-reached' event.
 */
import { useEffect, useRef } from "react";
import { on, emit } from "../lib/events";
import { useToast } from "./Toast";

export default function ApiErrorToaster() {
  const toast = useToast();
  const serverDownShown = useRef(false);

  useEffect(() => {
    return on("api:error", (e) => {
      const method = e?.method || "GET";
      const _url = e?.url || "";  // Reserved for future logging
      const status = e?.status ?? "";
      const msg = e?.message || "Request failed";
      const detail = e?.detail;

      // Check if this is a tier limit error
      if (status === 403 && detail?.code === "TIER_LIMIT_EXCEEDED") {
        // Emit special event for upgrade modal
        emit("tier:limit-reached", {
          resource: detail.resource,
          limit: detail.limit,
          current: detail.current,
          tier: detail.tier,
          message: detail.message,
        });
        return; // Don't show regular toast for tier limits
      }

      // Handle server unavailable (502, 503, network errors) gracefully
      // Don't spam toasts - just redirect to login once
      if (status === 502 || status === 503 || status === 0 || msg.includes("Failed to fetch") || msg.includes("Network")) {
        if (!serverDownShown.current) {
          serverDownShown.current = true;
          toast.info("Server is starting up...");
          // Redirect to login after a brief delay
          setTimeout(() => {
            if (window.location.pathname !== "/admin/login") {
              window.location.href = "/admin/login";
            }
            serverDownShown.current = false;
          }, 2000);
        }
        return;
      }

      toast.error(`${method} ${status} • ${msg}`);
      // why: visible debugging without opening the console
    });
  }, [toast]);
  return null;
}

