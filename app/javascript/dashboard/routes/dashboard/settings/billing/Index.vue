<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import EnterpriseInquiryModal from './components/EnterpriseInquiryModal.vue';
import DowngradePlanWarningModal from './components/DowngradePlanWarningModal.vue';
import PlanCheckoutModal from './components/PlanCheckoutModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import countries from 'shared/constants/countries.js';

const router = useRouter();
const { t, te } = useI18n();
const { currentAccount, isOnChatwootCloud, isCloudFeatureEnabled } =
  useAccount();
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
  isFetchingLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const purchaseCreditsModalRef = ref(null);
const enterpriseInquiryModalRef = ref(null);
const downgradeWarningModalRef = ref(null);
const planCheckoutModalRef = ref(null);
const showPlanPicker = ref(false);
const billingCountry = ref(
  currentAccount.value?.custom_attributes?.billing_country || ''
);
const countryOptions = countries.map(country => ({
  value: country.id,
  label: `${country.emoji} ${country.name}`,
}));

const accountSubscription = computed(
  () => currentAccount.value?.subscription || null
);
const hasActiveSubscription = computed(
  () => !!accountSubscription.value?.active
);
const lockedPaymentProvider = computed(() => {
  if (!hasActiveSubscription.value) return null;
  return (
    accountSubscription.value?.payment_provider ||
    currentAccount.value?.custom_attributes?.payment_provider ||
    null
  );
});
// Country picker is only for first-time / inactive accounts. An active plan
// locks the gateway so the customer cannot switch Stripe <-> Razorpay mid-cycle.
const showBillingCountrySelect = computed(() => !hasActiveSubscription.value);
const effectiveBillingCountry = computed(() => {
  if (lockedPaymentProvider.value === 'razorpay') return 'IN';
  if (lockedPaymentProvider.value === 'stripe') {
    return billingCountry.value || 'US';
  }
  return billingCountry.value;
});
const isIndiaBillingCountry = computed(
  () => effectiveBillingCountry.value === 'IN'
);
const paymentProviderLabel = computed(() => {
  if (lockedPaymentProvider.value === 'razorpay') {
    return t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_RAZORPAY');
  }
  if (lockedPaymentProvider.value === 'stripe') {
    return t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_STRIPE');
  }
  return isIndiaBillingCountry.value
    ? t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_RAZORPAY')
    : t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_STRIPE');
});
const usesStripePortal = computed(
  () => !lockedPaymentProvider.value || lockedPaymentProvider.value === 'stripe'
);

// Order matters here - used to detect downgrades and to show the retention
// window in the downgrade warning. Keep in sync with
// lib/seeders/plan_feature_limit_seeder.rb RESOURCE_LIMITS['data_retention_months'].
const PLAN_RANK = { Hobby: 0, Standard: 1, Business: 2, Enterprise: 3 };
const PLAN_RETENTION_MONTHS = {
  Hobby: 1,
  Standard: 6,
  Business: 12,
  Enterprise: null,
};

// Reseller & Client Billing States
// `is_reseller` alone is not enough - the reseller_dashboard capability
// must also be enabled on the account for the dashboard to be usable.
const isReseller = computed(
  () =>
    !!currentAccount.value.is_reseller &&
    isCloudFeatureEnabled(FEATURE_FLAGS.RESELLER_DASHBOARD)
);
const hasResellerParent = computed(() => !!currentAccount.value.parent_id);

const isFetchingMarketplace = ref(false);
const marketplaceData = ref({
  connected_account: null,
  prices: [],
});

const planCatalog = ref([]);
const fetchPlanCatalog = async () => {
  try {
    const response = await EnterpriseAccountAPI.getPlans();
    planCatalog.value = response.data;
  } catch (error) {
    // Non-fatal - the plan picker still works without prices shown.
  }
};
const planPriceLabel = planName => {
  const plan = planCatalog.value.find(p => p.name === planName);
  if (!plan || !plan.price_per_agent) {
    return t('BILLING_SETTINGS.SELECT_PLAN.CUSTOM_PRICING');
  }
  return t('BILLING_SETTINGS.SELECT_PLAN.PRICE_PER_MONTH', {
    price: plan.price_per_agent,
  });
};

const agencyPriceInput = ref(0);
const selectedCurrency = ref('usd');

const commissionPercent = computed(() => {
  return marketplaceData.value.connected_account?.commission_percent || 30;
});

const platformFeeAmount = computed(() => {
  const price = parseFloat(agencyPriceInput.value || 0);
  return ((price * commissionPercent.value) / 100).toFixed(2);
});

const totalClientPrice = computed(() => {
  const price = parseFloat(agencyPriceInput.value || 0);
  const fee = parseFloat(platformFeeAmount.value || 0);
  return (price + fee).toFixed(2);
});

const activePlanPrice = computed(() => {
  const preferred =
    marketplaceData.value.connected_account?.payment_provider === 'razorpay'
      ? 'inr'
      : 'usd';
  return (
    marketplaceData.value.prices?.find(
      p => p.currency === preferred && p.active
    ) || marketplaceData.value.prices?.find(p => p.active)
  );
});

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const planName = computed(() => {
  return customAttributes.value.plan_name;
});

const canPurchaseCredits = computed(() => {
  const plan = planName.value?.toLowerCase();
  // Hobby (and legacy Hacker) are free tiers - top-ups require a paid plan.
  return plan && !['hobby', 'hacker'].includes(plan);
});

const hasABillingPlan = computed(() => {
  return !!planName.value;
});

const accountLimits = computed(() => currentAccount.value?.limits || {});

const agentLimits = computed(() => {
  const limits = accountLimits.value?.agents;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const inboxLimits = computed(() => {
  const limits = accountLimits.value?.non_web_inboxes;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const conversationLimits = computed(() => {
  const limits = accountLimits.value?.conversation;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const contactLimits = computed(() => {
  const limits = accountLimits.value?.contacts;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const automationLimits = computed(() => {
  const limits = accountLimits.value?.automations;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const t3SubaccountLimits = computed(() => {
  const limits = accountLimits.value?.t3_subaccounts;
  if (!limits) return null;
  return { consumed: limits.consumed, totalCount: limits.allowed };
});

const dataRetentionLabel = computed(() => {
  const months = accountLimits.value?.data_retention_months;
  return months
    ? t('BILLING_SETTINGS.CURRENT_PLAN.RETENTION_MONTHS', { months })
    : t('BILLING_SETTINGS.CURRENT_PLAN.RETENTION_UNLIMITED');
});

const transactions = ref([]);
const isFetchingTransactions = ref(false);

const formatTransactionDate = value => {
  return value ? format(new Date(value), 'dd MMM, yyyy') : '';
};

const formatBillingDate = value => {
  return value ? format(new Date(value), 'dd MMM, yyyy') : '—';
};

const formatMoneyAmount = (amount, currency) => {
  const code = (currency || 'usd').toUpperCase();
  const locale = code === 'INR' ? 'en-IN' : 'en-US';
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: code,
  }).format(Number(amount || 0));
};

const formatTransactionAmount = transaction => {
  return formatMoneyAmount(transaction.amount, transaction.currency);
};

const PAST_DUE_STATUSES = ['past_due', 'unpaid'];

const subscriptionStatusLabel = computed(() => {
  const status = accountSubscription.value?.status;
  if (!status) return '—';
  const key = `BILLING_SETTINGS.SUBSCRIPTION.STATUS_${status.toUpperCase().replace(/-/g, '_')}`;
  return te(key) ? t(key) : status;
});

const isSubscriptionPaymentPending = computed(() => {
  const status = accountSubscription.value?.status;
  return status && PAST_DUE_STATUSES.includes(status);
});

const subscriptionPeriodEndLabel = computed(() => {
  if (accountSubscription.value?.cancel_at_period_end) {
    return t('BILLING_SETTINGS.SUBSCRIPTION.ACCESS_UNTIL');
  }
  return t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON');
});

const subscriptionPeriodEndValue = computed(() => {
  const endAt =
    accountSubscription.value?.current_period_end ||
    customAttributes.value?.subscription_ends_on;
  return formatBillingDate(endAt);
});

const subscriptionPeriodStartValue = computed(() => {
  return formatBillingDate(accountSubscription.value?.current_period_start);
});

const nextPaymentRetryValue = computed(() => {
  if (!isSubscriptionPaymentPending.value) return null;
  return formatBillingDate(accountSubscription.value?.grace_period_ends_at);
});

const currentPlanPriceLabel = computed(() => {
  const plan = planCatalog.value.find(p => p.name === planName.value);
  if (!plan?.price_per_agent) {
    return t('BILLING_SETTINGS.SELECT_PLAN.CUSTOM_PRICING');
  }
  const currency =
    accountSubscription.value?.payment_provider === 'razorpay' ? 'inr' : 'usd';
  return `${formatMoneyAmount(plan.price_per_agent, currency)}/${t('BILLING_SETTINGS.PLAN_CHECKOUT.PER_MONTH')}`;
});

const lastPayment = computed(() => transactions.value[0] || null);

const paymentProviderDisplay = computed(() => {
  const provider = accountSubscription.value?.payment_provider;
  if (provider === 'razorpay') {
    return t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_RAZORPAY');
  }
  if (provider === 'stripe') {
    return t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_STRIPE');
  }
  return '—';
});

const cancellationScheduledLabel = computed(() => {
  if (!accountSubscription.value?.cancel_at_period_end) return null;
  return t('BILLING_SETTINGS.SUBSCRIPTION.CANCELLATION_SCHEDULED');
});

const fetchMarketplaceData = async () => {
  if (isReseller.value || hasResellerParent.value) {
    isFetchingMarketplace.value = true;
    try {
      const response = await window.axios.get(
        `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`
      );
      marketplaceData.value = response.data;
      const preferredCurrency =
        response.data.connected_account?.payment_provider === 'razorpay'
          ? 'inr'
          : 'usd';
      selectedCurrency.value = preferredCurrency;
      const activePrice = response.data.prices?.find(
        p => p.currency === preferredCurrency && p.active
      );
      if (activePrice) {
        agencyPriceInput.value = activePrice.agency_price;
      }
    } catch {
      // Marketplace pricing is optional; keep the billing page usable without it.
    } finally {
      isFetchingMarketplace.value = false;
    }
  }
};

const handleConnectStripe = async () => {
  try {
    const country =
      currentAccount.value?.custom_attributes?.billing_country ||
      billingCountry.value ||
      'US';
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/connected_account`,
      {
        country,
        refresh_url: window.location.href,
        return_url: window.location.href,
      }
    );
    if (response.data.onboarding_url) {
      window.location.href = response.data.onboarding_url;
    }
  } catch (error) {
    useAlert(
      error.response?.data?.error || 'Payment onboarding request failed'
    );
  }
};

const handleSavePricing = async () => {
  try {
    await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`,
      {
        marketplace_plan_price: {
          currency: selectedCurrency.value,
          agency_price: agencyPriceInput.value,
        },
      }
    );
    useAlert(t('BILLING_SETTINGS.RESELLER.SAVE_SUCCESS'));
    fetchMarketplaceData();
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to save pricing');
  }
};

const handleSubscribe = async () => {
  try {
    const currency =
      marketplaceData.value.connected_account?.payment_provider === 'razorpay'
        ? 'inr'
        : 'usd';
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_checkout`,
      {
        currency,
        success_url: window.location.href,
        cancel_url: window.location.href,
      }
    );
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || 'Checkout initialization failed');
  }
};

const openEnterpriseInquiryModal = () => {
  enterpriseInquiryModalRef.value?.open();
};

const fetchAccountDetails = async () => {
  await store.dispatch('accounts/get', currentAccount.value.id);
  fetchLimits();
};

const handleBillingPageLogic = async () => {
  // If self-hosted, redirect to dashboard
  if (!isOnChatwootCloud.value) {
    router.push({ name: 'home' });
    return;
  }

  // Load marketplace data if reseller or client
  if (isReseller.value || hasResellerParent.value) {
    await fetchMarketplaceData();
  } else {
    await fetchPlanCatalog();
  }

  await fetchAccountDetails();
};

const onClickBillingPortal = () => {
  if (!usesStripePortal.value) {
    useAlert(t('BILLING_SETTINGS.SELECT_PLAN.RAZORPAY_MANAGE_HINT'));
    return;
  }
  store.dispatch('accounts/checkout');
};

const isCancelingSubscription = ref(false);
const onCancelRazorpaySubscription = async () => {
  isCancelingSubscription.value = true;
  try {
    await EnterpriseAccountAPI.cancelSubscription({ cancelAtCycleEnd: true });
    useAlert(t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_SUCCESS'));
    await store.dispatch('accounts/get', currentAccount.value.id);
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_ERROR')
    );
  } finally {
    isCancelingSubscription.value = false;
  }
};

const topupPaymentProvider = computed(() => {
  return (
    lockedPaymentProvider.value ||
    (isIndiaBillingCountry.value ? 'razorpay' : 'stripe')
  );
});

const isCheckingOut = ref(false);
const handlePlanCheckoutProceed = async ({
  planName: selectedPlanName,
  country,
  couponCode,
}) => {
  isCheckingOut.value = true;
  planCheckoutModalRef.value?.setProceeding(true);
  try {
    const response = await EnterpriseAccountAPI.planCheckout({
      planName: selectedPlanName,
      country,
      couponCode,
      successUrl: window.location.href,
      cancelUrl: window.location.href,
    });
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
      return;
    }
    useAlert('Failed to start checkout');
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to start checkout');
  } finally {
    isCheckingOut.value = false;
    planCheckoutModalRef.value?.setProceeding(false);
  }
};

const openPlanCheckoutModal = selectedPlan => {
  planCheckoutModalRef.value?.open(selectedPlan);
};

const handlePlanSelection = selectedPlan => {
  if (selectedPlan === 'Enterprise') {
    openEnterpriseInquiryModal();
    return;
  }

  const isDowngrade =
    planName.value && PLAN_RANK[selectedPlan] < PLAN_RANK[planName.value];
  if (isDowngrade) {
    downgradeWarningModalRef.value?.open(
      selectedPlan,
      PLAN_RETENTION_MONTHS[selectedPlan]
    );
    return;
  }

  openPlanCheckoutModal(selectedPlan);
};

const handleDowngradeConfirm = selectedPlan => {
  downgradeWarningModalRef.value?.close();
  openPlanCheckoutModal(selectedPlan);
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const openPurchaseCreditsModal = () => {
  purchaseCreditsModalRef.value?.open();
};

const fetchTransactions = async () => {
  isFetchingTransactions.value = true;
  try {
    const response = await EnterpriseAccountAPI.getTransactions();
    transactions.value = response.data;
  } catch (error) {
    // Silently ignore - payment history is supplementary, not critical to the page.
  } finally {
    isFetchingTransactions.value = false;
  }
};

onMounted(() => {
  handleBillingPageLogic();
  fetchTransactions();
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem || isFetchingMarketplace"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="
          isReseller
            ? $t('BILLING_SETTINGS.RESELLER.TITLE')
            : $t('BILLING_SETTINGS.TITLE')
        "
        :description="
          isReseller
            ? $t('BILLING_SETTINGS.RESELLER.DESCRIPTION')
            : $t('BILLING_SETTINGS.DESCRIPTION')
        "
        :link-text="isReseller ? '' : $t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <!-- Marketplace client: subscribes to the pricing their reseller parent
           published, instead of picking a direct platform plan. -->
      <section v-if="hasResellerParent" class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.CLIENT.TITLE')"
          :description="$t('BILLING_SETTINGS.CLIENT.DESCRIPTION')"
        >
          <div class="px-5 pb-5">
            <template v-if="activePlanPrice">
              <div
                class="grid sm:grid-cols-2 gap-2 divide-x divide-n-weak mb-4"
              >
                <DetailItem
                  :label="$t('BILLING_SETTINGS.RESELLER.TOTAL_PRICE')"
                  :value="`$${activePlanPrice.total_amount}/mo`"
                />
              </div>
              <ButtonV4
                solid
                blue
                :is-loading="isCheckingOut"
                @click="handleSubscribe"
              >
                {{ $t('BILLING_SETTINGS.CLIENT.SUBSCRIBE_BTN') }}
              </ButtonV4>
            </template>
            <p v-else class="text-n-slate-11 text-sm">
              {{ $t('BILLING_SETTINGS.CLIENT.NO_ACTIVE_PRICE') }}
            </p>
          </div>
        </BillingCard>
      </section>

      <!-- Reseller: manage Stripe Connect onboarding and publish client pricing. -->
      <section v-if="isReseller" class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.RESELLER.TITLE')"
          :description="$t('BILLING_SETTINGS.RESELLER.DESCRIPTION')"
        >
          <div class="px-5 pb-5 space-y-4">
            <div class="flex items-center justify-between">
              <span
                class="text-sm font-medium"
                :class="
                  marketplaceData.connected_account?.charges_enabled
                    ? 'text-n-teal-10'
                    : 'text-n-amber-10'
                "
              >
                {{
                  marketplaceData.connected_account?.charges_enabled
                    ? $t('BILLING_SETTINGS.RESELLER.STATUS_ONBOARDED')
                    : $t('BILLING_SETTINGS.RESELLER.STATUS_NOT_ONBOARDED')
                }}
              </span>
              <ButtonV4
                v-if="!marketplaceData.connected_account?.charges_enabled"
                sm
                solid
                blue
                @click="handleConnectStripe"
              >
                {{ $t('BILLING_SETTINGS.RESELLER.CONNECT_STRIPE') }}
              </ButtonV4>
            </div>
            <p
              v-if="!marketplaceData.connected_account?.charges_enabled"
              class="text-n-slate-11 text-sm"
            >
              {{ $t('BILLING_SETTINGS.RESELLER.CONNECT_DESC') }}
            </p>

            <template v-if="marketplaceData.connected_account?.charges_enabled">
              <h4 class="text-sm font-medium text-n-slate-12">
                {{ $t('BILLING_SETTINGS.RESELLER.SET_PRICE') }}
              </h4>
              <div class="grid sm:grid-cols-3 gap-4">
                <Input
                  v-model="agencyPriceInput"
                  type="number"
                  min="1"
                  :label="$t('BILLING_SETTINGS.RESELLER.AGENCY_PRICE')"
                />
                <DetailItem
                  :label="
                    $t('BILLING_SETTINGS.RESELLER.COMMISSION', {
                      percent: commissionPercent,
                    })
                  "
                  :value="`$${platformFeeAmount}`"
                />
                <DetailItem
                  :label="$t('BILLING_SETTINGS.RESELLER.TOTAL_PRICE')"
                  :value="`$${totalClientPrice}`"
                />
              </div>
              <ButtonV4 solid blue @click="handleSavePricing">
                {{ $t('BILLING_SETTINGS.RESELLER.SAVE_PRICING') }}
              </ButtonV4>
            </template>
          </div>
        </BillingCard>
      </section>

      <!-- Direct Plan Selection Flow (Replaces Stripe Flows for Testing) -->
      <!-- Marketplace clients subscribe via their reseller's pricing above, not here. -->
      <section class="grid gap-4">
        <BillingCard
          v-if="!hasResellerParent && (!planName || showPlanPicker)"
          :title="$t('BILLING_SETTINGS.SELECT_PLAN.TITLE')"
          :description="$t('BILLING_SETTINGS.SELECT_PLAN.DESCRIPTION')"
        >
          <template v-if="planName" #action>
            <ButtonV4 sm flushed slate @click="showPlanPicker = false">
              {{ $t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_BUTTON') }}
            </ButtonV4>
          </template>
          <p
            v-if="lockedPaymentProvider"
            class="px-4 pt-4 text-xs text-n-slate-11"
          >
            {{
              $t('BILLING_SETTINGS.SELECT_PLAN.PROVIDER_LOCKED_HINT', {
                provider: paymentProviderLabel,
              })
            }}
          </p>
          <div
            v-if="lockedPaymentProvider === 'razorpay' && hasActiveSubscription"
            class="px-4 pt-2"
          >
            <ButtonV4
              sm
              solid
              slate
              :is-loading="isCancelingSubscription"
              @click="onCancelRazorpaySubscription"
            >
              {{
                $t('BILLING_SETTINGS.SELECT_PLAN.CANCEL_SUBSCRIPTION_BUTTON')
              }}
            </ButtonV4>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
            <div
              v-for="plan in ['Hobby', 'Standard', 'Business', 'Enterprise']"
              :key="plan"
              class="border border-n-weak rounded-xl p-6 bg-n-background shadow-sm flex flex-col justify-between gap-4"
            >
              <div>
                <div class="text-xl font-bold text-center text-n-slate-12">
                  {{ $t('BILLING_SETTINGS.SELECT_PLAN.PLAN_LABEL', { plan }) }}
                </div>
                <div class="text-sm text-center text-n-slate-11 mt-1">
                  {{ planPriceLabel(plan) }}
                </div>
              </div>
              <ButtonV4
                solid
                blue
                class="w-full justify-center"
                :is-loading="plan !== 'Enterprise' && isCheckingOut"
                @click="handlePlanSelection(plan)"
              >
                {{
                  plan === 'Enterprise'
                    ? $t('BILLING_SETTINGS.SELECT_PLAN.CONTACT_SALES_BUTTON')
                    : $t('BILLING_SETTINGS.SELECT_PLAN.SELECT_BUTTON')
                }}
              </ButtonV4>
            </div>
          </div>
        </BillingCard>

        <BillingCard
          v-if="!hasResellerParent && planName"
          :title="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
          :description="$t('BILLING_SETTINGS.SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                v-if="usesStripePortal && accountSubscription"
                sm
                flushed
                slate
                @click="onClickBillingPortal"
              >
                {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
              </ButtonV4>
              <ButtonV4 sm solid blue @click="showPlanPicker = true">
                {{ $t('BILLING_SETTINGS.CURRENT_PLAN.CHANGE_PLAN_BUTTON') }}
              </ButtonV4>
            </div>
          </template>
          <div class="px-5 pb-2">
            <p
              v-if="cancellationScheduledLabel"
              class="text-sm text-n-amber-11 mb-4"
            >
              {{ cancellationScheduledLabel }}
            </p>
            <p
              v-if="isSubscriptionPaymentPending"
              class="text-sm text-n-ruby-11 mb-4"
            >
              {{ $t('BILLING_SETTINGS.SUBSCRIPTION.PAYMENT_FAILED_HINT') }}
            </p>
          </div>
          <div
            class="grid lg:grid-cols-4 sm:grid-cols-2 grid-cols-1 gap-4 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName || '—'"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.STATUS')"
              :value="subscriptionStatusLabel"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.PLAN_PRICE')"
              :value="currentPlanPriceLabel"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.PAYMENT_PROVIDER')"
              :value="paymentProviderDisplay"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.PERIOD_START')"
              :value="subscriptionPeriodStartValue"
            />
            <DetailItem
              :label="subscriptionPeriodEndLabel"
              :value="subscriptionPeriodEndValue"
            />
            <DetailItem
              v-if="nextPaymentRetryValue"
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.NEXT_RETRY')"
              :value="nextPaymentRetryValue"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.DATA_RETENTION_LABEL')"
              :value="dataRetentionLabel"
            />
          </div>

          <div
            v-if="lastPayment"
            class="mx-5 mt-4 mb-5 rounded-lg border border-n-weak bg-n-solid-1 p-4"
          >
            <p class="text-sm font-medium text-n-slate-12 mb-3">
              {{ $t('BILLING_SETTINGS.SUBSCRIPTION.LAST_PAYMENT') }}
            </p>
            <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <DetailItem
                :label="$t('BILLING_SETTINGS.TRANSACTIONS.DATE')"
                :value="
                  formatTransactionDate(
                    lastPayment.paid_at || lastPayment.created_at
                  )
                "
              />
              <DetailItem
                :label="$t('BILLING_SETTINGS.TRANSACTIONS.AMOUNT')"
                :value="formatTransactionAmount(lastPayment)"
              />
              <DetailItem
                :label="$t('BILLING_SETTINGS.TRANSACTIONS.STATUS')"
                :value="
                  lastPayment.status === 'succeeded'
                    ? $t('BILLING_SETTINGS.TRANSACTIONS.STATUS_SUCCEEDED')
                    : $t('BILLING_SETTINGS.TRANSACTIONS.STATUS_FAILED')
                "
              />
              <DetailItem
                :label="$t('BILLING_SETTINGS.TRANSACTIONS.DESCRIPTION_COL')"
                :value="lastPayment.description || '—'"
              />
            </div>
            <a
              v-if="lastPayment.hosted_invoice_url"
              :href="lastPayment.hosted_invoice_url"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-block mt-3 text-sm text-n-blue-11 hover:underline"
            >
              {{ $t('BILLING_SETTINGS.TRANSACTIONS.VIEW') }}
            </a>
          </div>
        </BillingCard>

        <!-- Resource Limits -->
        <BillingCard
          v-if="hasABillingPlan"
          :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.TITLE')"
          :description="$t('BILLING_SETTINGS.RESOURCE_LIMITS.DESCRIPTION')"
        >
          <div class="px-5 pb-5 grid gap-4">
            <BillingMeter
              v-if="agentLimits"
              :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.SEATS')"
              v-bind="agentLimits"
            />
            <BillingMeter
              v-if="inboxLimits"
              :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.INBOXES')"
              v-bind="inboxLimits"
            />
            <BillingMeter
              v-if="contactLimits"
              :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.CONTACTS')"
              v-bind="contactLimits"
            />
            <BillingMeter
              v-if="conversationLimits"
              :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.CONVERSATIONS')"
              v-bind="conversationLimits"
            />
            <BillingMeter
              v-if="t3SubaccountLimits"
              :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.T3_SUBACCOUNTS')"
              v-bind="t3SubaccountLimits"
            />
            <BillingMeter
              v-if="automationLimits"
              :title="$t('BILLING_SETTINGS.RESOURCE_LIMITS.AUTOMATIONS')"
              v-bind="automationLimits"
            />
          </div>
        </BillingCard>

        <!-- Captain AI Billing -->
        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                sm
                flushed
                slate
                icon="i-lucide-refresh-cw"
                :is-loading="isFetchingLimits"
                @click="fetchLimits"
              >
                {{ $t('BILLING_SETTINGS.CAPTAIN.REFRESH_CREDITS') }}
              </ButtonV4>
              <ButtonV4
                v-if="canPurchaseCredits"
                sm
                solid
                blue
                @click="openPurchaseCreditsModal"
              >
                {{ $t('BILLING_SETTINGS.TOPUP.BUY_CREDITS') }}
              </ButtonV4>
            </div>
          </template>
          <div v-if="captainLimits && responseLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="responseLimits"
            />
          </div>
          <div v-if="captainLimits && documentLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
              v-bind="documentLimits"
            />
          </div>
        </BillingCard>

        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <ButtonV4 sm solid slate @click="onClickBillingPortal">
              {{ $t('CAPTAIN.PAYWALL.UPGRADE_NOW') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <!-- Payment History -->
        <BillingCard
          v-if="hasABillingPlan"
          :title="$t('BILLING_SETTINGS.TRANSACTIONS.TITLE')"
          :description="$t('BILLING_SETTINGS.TRANSACTIONS.DESCRIPTION')"
        >
          <div class="px-5 pb-5 overflow-x-auto">
            <p
              v-if="isFetchingTransactions"
              class="text-sm text-n-slate-11 py-2"
            >
              {{ $t('BILLING_SETTINGS.TRANSACTIONS.LOADING') }}
            </p>
            <p
              v-else-if="!transactions.length"
              class="text-sm text-n-slate-11 py-2"
            >
              {{ $t('BILLING_SETTINGS.TRANSACTIONS.EMPTY') }}
            </p>
            <table v-else class="w-full text-sm">
              <thead>
                <tr class="text-left text-n-slate-11 border-b border-n-weak">
                  <th class="py-2 pr-4 font-medium">
                    {{ $t('BILLING_SETTINGS.TRANSACTIONS.DATE') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ $t('BILLING_SETTINGS.TRANSACTIONS.DESCRIPTION_COL') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ $t('BILLING_SETTINGS.TRANSACTIONS.AMOUNT') }}
                  </th>
                  <th class="py-2 pr-4 font-medium">
                    {{ $t('BILLING_SETTINGS.TRANSACTIONS.STATUS') }}
                  </th>
                  <th class="py-2 font-medium">
                    {{ $t('BILLING_SETTINGS.TRANSACTIONS.RECEIPT') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="transaction in transactions"
                  :key="transaction.id"
                  class="border-b border-n-weak last:border-0"
                >
                  <td class="py-2 pr-4 text-n-slate-12 whitespace-nowrap">
                    {{
                      formatTransactionDate(
                        transaction.paid_at || transaction.created_at
                      )
                    }}
                  </td>
                  <td class="py-2 pr-4 text-n-slate-12">
                    {{ transaction.description || '—' }}
                  </td>
                  <td class="py-2 pr-4 text-n-slate-12 whitespace-nowrap">
                    {{ formatTransactionAmount(transaction) }}
                  </td>
                  <td class="py-2 pr-4">
                    <span
                      class="px-2 py-0.5 rounded-full text-xs font-medium"
                      :class="
                        transaction.status === 'succeeded'
                          ? 'bg-n-teal-3 text-n-teal-11'
                          : 'bg-n-ruby-3 text-n-ruby-11'
                      "
                    >
                      {{
                        transaction.status === 'succeeded'
                          ? $t('BILLING_SETTINGS.TRANSACTIONS.STATUS_SUCCEEDED')
                          : $t('BILLING_SETTINGS.TRANSACTIONS.STATUS_FAILED')
                      }}
                    </span>
                  </td>
                  <td class="py-2">
                    <a
                      v-if="transaction.hosted_invoice_url"
                      :href="transaction.hosted_invoice_url"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="text-n-blue-11 hover:underline"
                    >
                      {{ $t('BILLING_SETTINGS.TRANSACTIONS.VIEW') }}
                    </a>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </BillingCard>

        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @click="onToggleChatWindow"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>

      <PurchaseCreditsModal
        ref="purchaseCreditsModalRef"
        :payment-provider="topupPaymentProvider"
      />
      <EnterpriseInquiryModal ref="enterpriseInquiryModalRef" />
      <DowngradePlanWarningModal
        ref="downgradeWarningModalRef"
        @confirm="handleDowngradeConfirm"
      />
      <PlanCheckoutModal
        ref="planCheckoutModalRef"
        :show-country-select="showBillingCountrySelect"
        :locked-payment-provider="lockedPaymentProvider"
        :initial-country="billingCountry"
        :country-options="countryOptions"
        @proceed="handlePlanCheckoutProceed"
      />
    </template>
  </SettingsLayout>
</template>
