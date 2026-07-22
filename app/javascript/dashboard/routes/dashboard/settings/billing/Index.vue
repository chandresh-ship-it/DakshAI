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

const fetchMarketplaceData = async () => {
  if (isReseller.value || hasResellerParent.value) {
    isFetchingMarketplace.value = true;
    try {
      const response = await window.axios.get(`/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`);
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
    const response = await window.axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/connected_account`, {
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
    await window.axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`, {
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
    const response = await window.axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_checkout`, {
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

const isBypassingPlan = ref(false);
const handleBypassPlan = async (planName) => {
  isBypassingPlan.value = true;
  try {
    const response = await window.axios.post(`/enterprise/api/v1/accounts/${currentAccount.value.id}/bypass_plan`, {
      plan_name: planName
    });
    useAlert(`Successfully switched to ${planName} plan!`);
    await fetchAccountDetails();
    window.location.reload();
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to switch plan');
  } finally {
    isBypassingPlan.value = false;
  }
};

const fetchAccountDetails = async () => {
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

  await fetchAccountDetails();
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
    :is-loading="uiFlags.isFetchingItem || isFetchingMarketplace"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
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
      <!-- Direct Plan Selection Flow (Replaces Stripe Flows for Testing) -->
      <section class="grid gap-4">
        <BillingCard
          v-if="!planName"
          :title="$t('BILLING_SETTINGS.SELECT_PLAN.TITLE')"
          :description="$t('BILLING_SETTINGS.SELECT_PLAN.DESCRIPTION')"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
            <div
              v-for="plan in ['Hobby', 'Standard', 'Business', 'Enterprise']"
              :key="plan"
              class="border border-n-weak rounded-xl p-6 bg-n-background shadow-sm flex flex-col justify-between gap-4"
            >
              <div class="text-xl font-bold text-center text-n-slate-12">
                {{ $t('BILLING_SETTINGS.SELECT_PLAN.PLAN_LABEL', { plan }) }}
              </div>
              <ButtonV4
                solid
                blue
                class="w-full justify-center"
                :is-loading="isBypassingPlan"
                @click="handleBypassPlan(plan)"
              >
                {{ $t('BILLING_SETTINGS.SELECT_PLAN.SELECT_BUTTON') }}
              </ButtonV4>
            </div>
          </div>
        </BillingCard>

        <BillingCard
          v-if="planName"
          :title="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
        >
          <div class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak">
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
          </div>
        </BillingCard>

        <!-- Resource Limits -->
        <BillingCard
          v-if="hasABillingPlan"
          title="Resource Limits"
          description="Usage and limits for your current billing cycle."
        >
          <div class="px-5 pb-5 grid gap-4">
            <BillingMeter
              v-if="agentLimits"
              title="Seats (team members)"
              v-bind="agentLimits"
            />
            <BillingMeter
              v-if="inboxLimits"
              title="Inboxes"
              v-bind="inboxLimits"
            />
            <BillingMeter
              v-if="contactLimits"
              title="Contacts"
              v-bind="contactLimits"
            />
            <BillingMeter
              v-if="conversationLimits"
              title="Conversations/month"
              v-bind="conversationLimits"
            />
            <BillingMeter
              v-if="t3SubaccountLimits"
              title="T3 Reseller Sub-accounts"
              v-bind="t3SubaccountLimits"
            />
            <BillingMeter
              v-if="automationLimits"
              title="Automations/workflows"
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
