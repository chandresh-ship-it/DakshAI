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
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const router = useRouter();
const { t } = useI18n();
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
const showPlanPicker = ref(false);

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
  return t('BILLING_SETTINGS.SELECT_PLAN.PRICE_PER_AGENT', {
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
  return marketplaceData.value.prices?.find(
    p => p.currency === 'usd' && p.active
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

const fetchMarketplaceData = async () => {
  if (isReseller.value || hasResellerParent.value) {
    isFetchingMarketplace.value = true;
    try {
      const response = await window.axios.get(
        `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_pricing`
      );
      marketplaceData.value = response.data;
      const usdPrice = response.data.prices?.find(
        p => p.currency === 'usd' && p.active
      );
      if (usdPrice) {
        agencyPriceInput.value = usdPrice.agency_price;
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
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/connected_account`,
      {
        country: 'US',
        refresh_url: window.location.href,
        return_url: window.location.href,
      }
    );
    if (response.data.onboarding_url) {
      window.location.href = response.data.onboarding_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || 'Stripe onboarding request failed');
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
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/marketplace_checkout`,
      {
        currency: 'usd',
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
  store.dispatch('accounts/checkout');
};

const isCheckingOut = ref(false);
const startPlanCheckout = async selectedPlan => {
  isCheckingOut.value = true;
  try {
    const response = await window.axios.post(
      `/enterprise/api/v1/accounts/${currentAccount.value.id}/plan_checkout`,
      {
        plan_name: selectedPlan,
        success_url: window.location.href,
        cancel_url: window.location.href,
      }
    );
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || 'Failed to start checkout');
    isCheckingOut.value = false;
  }
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

  startPlanCheckout(selectedPlan);
};

const handleDowngradeConfirm = selectedPlan => {
  downgradeWarningModalRef.value?.close();
  startPlanCheckout(selectedPlan);
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const openPurchaseCreditsModal = () => {
  purchaseCreditsModalRef.value?.open();
};

const transactions = ref([]);
const isFetchingTransactions = ref(false);
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

const formatTransactionDate = value => {
  return value ? format(new Date(value), 'dd MMM, yyyy') : '';
};

const formatTransactionAmount = transaction => {
  return `${Number(transaction.amount || 0).toFixed(2)} ${(transaction.currency || '').toUpperCase()}`;
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
        >
          <template #action>
            <ButtonV4 sm solid blue @click="showPlanPicker = true">
              {{ $t('BILLING_SETTINGS.CURRENT_PLAN.CHANGE_PLAN_BUTTON') }}
            </ButtonV4>
          </template>
          <div
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.DATA_RETENTION_LABEL')"
              :value="dataRetentionLabel"
            />
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

      <PurchaseCreditsModal ref="purchaseCreditsModalRef" />
      <EnterpriseInquiryModal ref="enterpriseInquiryModalRef" />
      <DowngradePlanWarningModal
        ref="downgradeWarningModalRef"
        @confirm="handleDowngradeConfirm"
      />
    </template>
  </SettingsLayout>
</template>
