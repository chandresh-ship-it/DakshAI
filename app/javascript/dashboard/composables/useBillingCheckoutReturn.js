import { useRoute, useRouter } from 'vue-router';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const PENDING_CHECKOUT_KEY = 'billing_checkout_pending';
const PENDING_CHECKOUT_TTL_MS = 24 * 60 * 60 * 1000;

const readPendingCheckout = () => {
  try {
    const raw = sessionStorage.getItem(PENDING_CHECKOUT_KEY);
    if (!raw) return null;

    const pending = JSON.parse(raw);
    if (!pending?.checkoutRef || !pending?.checkoutType) return null;
    if (Date.now() - pending.startedAt > PENDING_CHECKOUT_TTL_MS) {
      sessionStorage.removeItem(PENDING_CHECKOUT_KEY);
      return null;
    }

    return pending;
  } catch {
    sessionStorage.removeItem(PENDING_CHECKOUT_KEY);
    return null;
  }
};

const clearPendingCheckout = () => {
  sessionStorage.removeItem(PENDING_CHECKOUT_KEY);
};

const rememberPendingCheckout = (checkoutRef, checkoutType) => {
  sessionStorage.setItem(
    PENDING_CHECKOUT_KEY,
    JSON.stringify({
      checkoutRef,
      checkoutType,
      startedAt: Date.now(),
    })
  );
};

export const buildCheckoutReturnUrls = checkoutType => {
  const checkoutRef = crypto.randomUUID();
  const base = `${window.location.origin}${window.location.pathname}`;
  const sharedParams = new URLSearchParams({
    checkout_ref: checkoutRef,
    checkout_type: checkoutType,
  });

  return {
    successUrl: `${base}?checkout_return=success&${sharedParams}`,
    cancelUrl: `${base}?checkout_return=cancel&${sharedParams}`,
    checkoutRef,
    checkoutType,
  };
};

export const markCheckoutRedirected = ({ checkoutRef, checkoutType }) => {
  rememberPendingCheckout(checkoutRef, checkoutType);
};

export function useBillingCheckoutReturn() {
  const route = useRoute();
  const router = useRouter();

  const recordCheckoutReturn = async ({
    returnType,
    checkoutType,
    checkoutRef,
  }) => {
    await EnterpriseAccountAPI.recordCheckoutReturn({
      returnType,
      checkoutType,
      checkoutRef,
    });
  };

  const processCheckoutReturn = async () => {
    const returnType = route.query.checkout_return;
    const checkoutType = route.query.checkout_type;
    const checkoutRef = route.query.checkout_ref;

    if (returnType && checkoutType) {
      clearPendingCheckout();
      try {
        await recordCheckoutReturn({
          returnType,
          checkoutType,
          checkoutRef,
        });
      } catch {
        // Non-fatal — billing page should still load normally.
      }

      const query = { ...route.query };
      delete query.checkout_return;
      delete query.checkout_type;
      delete query.checkout_ref;
      router.replace({ query });
      return;
    }

    const pending = readPendingCheckout();
    if (!pending) return;

    clearPendingCheckout();
    try {
      await recordCheckoutReturn({
        returnType: 'cancel',
        checkoutType: pending.checkoutType,
        checkoutRef: pending.checkoutRef,
      });
    } catch {
      // Non-fatal — billing page should still load normally.
    }
  };

  return {
    buildCheckoutReturnUrls,
    processCheckoutReturn,
  };
}
