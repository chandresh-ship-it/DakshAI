<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import sessionStorage from 'shared/helpers/sessionStorage';
import axios from 'axios';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const router = useRouter();
const { t } = useI18n();
const { currentAccount, isOnChatwootCloud } = useAccount();
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

const BILLING_REFRESH_ATTEMPTED = 'billing_refresh_attempted';

// State for handling refresh attempts and loading
const isWaitingForBilling = ref(false);
const purchaseCreditsModalRef = ref(null);

// Reseller & Client Billing States
const isReseller = computed(() => !!currentAccount.value.is_reseller);
const hasResellerParent = computed(() => !!currentAccount.value.parent_id);

const isFetchingMarketplace = ref(false);
const marketplaceData = ref({
  connected_account: null,
  prices: []
});

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
  return marketplaceData.value.prices?.find(p => p.currency === 'usd' && p.active);
});

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const planName = computed(() => {
  return customAttributes.value.plan_name;
});

const canPurchaseCredits = computed(() => {
  const plan = planName.value?.toLowerCase();
  return plan && plan !== 'hacker';
});

const subscribedQuantity = computed(() => {
  return customAttributes.value.subscribed_quantity;
});

const subscriptionRenewsOn = computed(() => {
  if (!customAttributes.value.subscription_ends_on) return '';
  const endDate = new Date(customAttributes.value.subscription_ends_on);
  return format(endDate, 'dd MMM, yyyy');
});

const hasABillingPlan = computed(() => {
  return !!planName.value;
});

const fetchMarketplaceData = async () => {
  if (isReseller.value || hasResellerParent.value) {
    isFetchingMarketplace.value = true;
    try {
      const response = await axios.get(`/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`);
      marketplaceData.value = response.data;
      const usdPrice = response.data.prices?.find(p => p.currency === 'usd' && p.active);
      if (usdPrice) {
        agencyPriceInput.value = usdPrice.agency_price;
      }
    } catch (error) {
      console.error(error);
    } finally {
      isFetchingMarketplace.value = false;
    }
  }
};

const handleConnectStripe = async () => {
  try {
    const response = await axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/connected_account`, {
      country: 'US',
      refresh_url: window.location.href,
      return_url: window.location.href
    });
    if (response.data.onboarding_url) {
      window.location.href = response.data.onboarding_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || 'Stripe onboarding request failed');
  }
};

const handleSavePricing = async () => {
  try {
    await axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`, {
      marketplace_plan_price: {
        currency: selectedCurrency.value,
        agency_price: agencyPriceInput.value
      }
    });
    useAlert(t('BILLING_SETTINGS.RESELLER.SAVE_SUCCESS'));
    fetchMarketplaceData();
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to save pricing');
  }
};

const handleSubscribe = async () => {
  try {
    const response = await axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_checkout`, {
      currency: 'usd',
      success_url: window.location.href,
      cancel_url: window.location.href
    });
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || 'Checkout initialization failed');
  }
};

const fetchAccountDetails = async () => {
  if (!isReseller.value && !hasResellerParent.value && !hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
  }
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
  }

  const billingRefreshAttempted = sessionStorage.get(BILLING_REFRESH_ATTEMPTED);
  await fetchAccountDetails();

  if (!isReseller.value && !hasResellerParent.value && !hasABillingPlan.value) {
    if (!billingRefreshAttempted) {
      isWaitingForBilling.value = true;
      sessionStorage.set(BILLING_REFRESH_ATTEMPTED, true);
      setTimeout(() => {
        window.location.reload();
      }, 5000);
    } else {
      sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
    }
  } else {
    sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
  }
};

const onClickBillingPortal = () => {
  store.dispatch('accounts/checkout');
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const openPurchaseCreditsModal = () => {
  purchaseCreditsModalRef.value?.open();
};

const handleTopupSuccess = () => {
  fetchLimits();
};

onMounted(handleBillingPageLogic);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem || isWaitingForBilling || isFetchingMarketplace"
    :loading-message="
      isWaitingForBilling
        ? $t('BILLING_SETTINGS.NO_BILLING_USER')
        : $t('ATTRIBUTES_MGMT.LOADING')
    "
  >
    <template #header>
      <BaseSettingsHeader
        :title="isReseller ? $t('BILLING_SETTINGS.RESELLER.TITLE') : $t('BILLING_SETTINGS.TITLE')"
        :description="isReseller ? $t('BILLING_SETTINGS.RESELLER.DESCRIPTION') : $t('BILLING_SETTINGS.DESCRIPTION')"
        :link-text="isReseller ? '' : $t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <!-- Reseller (T2) Pricing Panel View -->
      <section v-if="isReseller" class="grid gap-4">
        <!-- Stripe Connect Onboarding -->
        <BillingCard
          v-if="!marketplaceData.connected_account?.charges_enabled"
          :title="$t('BILLING_SETTINGS.RESELLER.CONNECT_STRIPE')"
          :description="$t('BILLING_SETTINGS.RESELLER.CONNECT_DESC')"
        >
          <template #action>
            <ButtonV4 sm solid blue @click="handleConnectStripe">
              {{ $t('BILLING_SETTINGS.RESELLER.CONNECT_STRIPE') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <!-- Pricing Configuration -->
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.RESELLER.TITLE')"
          description="Manage the pricing plan offered to your clients."
        >
          <div class="max-w-md grid gap-4 p-2">
            <div class="flex flex-col gap-2">
              <label class="text-sm font-semibold">{{ $t('BILLING_SETTINGS.RESELLER.SET_PRICE') }}</label>
              <div class="flex gap-2">
                <input
                  v-model="agencyPriceInput"
                  type="number"
                  min="1"
                  class="flex-grow border border-n-weak rounded-xl px-4 py-2 bg-n-background focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Price in USD"
                />
                <ButtonV4 sm solid blue @click="handleSavePricing">
                  {{ $t('BILLING_SETTINGS.RESELLER.SAVE_PRICING') }}
                </ButtonV4>
              </div>
            </div>

            <!-- Fee Breakdown Calculator -->
            <div class="grid gap-2 border border-n-weak rounded-xl p-4 bg-n-slate-2">
              <div class="flex justify-between text-sm">
                <span>{{ $t('BILLING_SETTINGS.RESELLER.AGENCY_PRICE') }}</span>
                <span class="font-semibold">${{ parseFloat(agencyPriceInput || 0).toFixed(2) }}</span>
              </div>
              <div class="flex justify-between text-sm text-n-slate-11">
                <span>{{ $t('BILLING_SETTINGS.RESELLER.COMMISSION', { percent: commissionPercent }) }}</span>
                <span>+${{ platformFeeAmount }}</span>
              </div>
              <hr class="border-n-weak my-1" />
              <div class="flex justify-between font-bold text-base">
                <span>{{ $t('BILLING_SETTINGS.RESELLER.TOTAL_PRICE') }}</span>
                <span class="text-blue-600">${{ totalClientPrice }}</span>
              </div>
            </div>
          </div>
        </BillingCard>
      </section>

      <!-- Client (T3) Billing view -->
      <section v-else-if="hasResellerParent" class="grid gap-4">
        <BillingCard
          v-if="hasABillingPlan"
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm solid blue @click="onClickBillingPortal">
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak">
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              value="Workspace Subscription"
            />
            <DetailItem
              v-if="subscribedQuantity"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="subscribedQuantity"
            />
            <DetailItem
              v-if="subscriptionRenewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
          </div>
        </BillingCard>

        <!-- No active subscription yet: Show plan configuration -->
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CLIENT.TITLE')"
          :description="$t('BILLING_SETTINGS.CLIENT.DESCRIPTION')"
        >
          <div v-if="activePlanPrice" class="grid gap-4 max-w-sm p-2">
            <div class="border border-n-weak rounded-2xl p-6 bg-n-background shadow-sm flex flex-col gap-4">
              <div class="text-xl font-bold text-center">Standard Workspace Plan</div>
              <div class="flex items-baseline justify-center gap-1">
                <span class="text-4xl font-extrabold text-blue-600">${{ activePlanPrice.total_amount }}</span>
                <span class="text-n-slate-11">/ month</span>
              </div>
              <ButtonV4 solid blue class="w-full justify-center" @click="handleSubscribe">
                {{ $t('BILLING_SETTINGS.CLIENT.SUBSCRIBE_BTN') }}
              </ButtonV4>
            </div>
          </div>
          <div v-else class="text-n-slate-11 p-4 border border-n-weak rounded-xl">
            {{ $t('BILLING_SETTINGS.CLIENT.NO_ACTIVE_PRICE') }}
          </div>
        </BillingCard>
      </section>

      <!-- Standard direct platform billing (Case 1) -->
      <section v-else class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm solid blue @click="onClickBillingPortal">
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div
            v-if="planName || subscribedQuantity || subscriptionRenewsOn"
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              v-if="subscribedQuantity"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="subscribedQuantity"
            />
            <DetailItem
              v-if="subscriptionRenewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
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
        @success="handleTopupSuccess"
      />
    </template>
  </SettingsLayout>
</template>
