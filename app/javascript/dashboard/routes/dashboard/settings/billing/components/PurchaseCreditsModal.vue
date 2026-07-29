<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CreditPackageCard from './CreditPackageCard.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import { buildCheckoutReturnUrls } from 'dashboard/composables/useBillingCheckoutReturn';

const props = defineProps({
  paymentProvider: {
    type: String,
    default: 'stripe',
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const STRIPE_TOPUP_OPTIONS = [
  { credits: 1000, amount: 20.0, currency: 'usd' },
  { credits: 2500, amount: 50.0, currency: 'usd' },
  { credits: 6000, amount: 100.0, currency: 'usd' },
  { credits: 12000, amount: 200.0, currency: 'usd' },
];

const RAZORPAY_TOPUP_OPTIONS = [
  { credits: 1000, amount: 1699.0, currency: 'inr' },
  { credits: 2500, amount: 4199.0, currency: 'inr' },
  { credits: 6000, amount: 8299.0, currency: 'inr' },
  { credits: 12000, amount: 16499.0, currency: 'inr' },
];

const TOPUP_OPTIONS = computed(() =>
  props.paymentProvider === 'razorpay'
    ? RAZORPAY_TOPUP_OPTIONS
    : STRIPE_TOPUP_OPTIONS
);

const POPULAR_CREDITS_AMOUNT = 6000;
const STEP_SELECT = 'select';
const STEP_CONFIRM = 'confirm';

const dialogRef = ref(null);
const selectedCredits = ref(null);
const isLoading = ref(false);
const currentStep = ref(STEP_SELECT);

const selectedOption = computed(() => {
  return TOPUP_OPTIONS.value.find(o => o.credits === selectedCredits.value);
});

const formattedAmount = computed(() => {
  if (!selectedOption.value) return '';
  return new Intl.NumberFormat(
    selectedOption.value.currency === 'inr' ? 'en-IN' : 'en-US',
    {
      style: 'currency',
      currency: selectedOption.value.currency.toUpperCase(),
    }
  ).format(selectedOption.value.amount);
});

const formattedCredits = computed(() => {
  if (!selectedOption.value) return '';
  return selectedOption.value.credits.toLocaleString();
});

const dialogTitle = computed(() => {
  return currentStep.value === STEP_SELECT
    ? t('BILLING_SETTINGS.TOPUP.MODAL_TITLE')
    : t('BILLING_SETTINGS.TOPUP.CONFIRM.TITLE');
});

const dialogDescription = computed(() => {
  return currentStep.value === STEP_SELECT
    ? t('BILLING_SETTINGS.TOPUP.MODAL_DESCRIPTION')
    : '';
});

const dialogWidth = computed(() => {
  return currentStep.value === STEP_SELECT ? 'xl' : 'md';
});

const handlePackageSelect = credits => {
  selectedCredits.value = credits;
};

const open = () => {
  const popularOption = TOPUP_OPTIONS.value.find(
    o => o.credits === POPULAR_CREDITS_AMOUNT
  );
  selectedCredits.value =
    popularOption?.credits || TOPUP_OPTIONS.value[0]?.credits;
  currentStep.value = STEP_SELECT;
  isLoading.value = false;
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleClose = () => {
  emit('close');
};

const goToConfirmStep = () => {
  if (!selectedOption.value) return;
  currentStep.value = STEP_CONFIRM;
};

const goBackToSelectStep = () => {
  currentStep.value = STEP_SELECT;
};

const handlePurchase = async () => {
  if (!selectedOption.value) return;

  isLoading.value = true;
  try {
    const { successUrl, cancelUrl } = buildCheckoutReturnUrls('topup_checkout');
    const response = await EnterpriseAccountAPI.createTopupCheckout(
      selectedOption.value.credits,
      {
        successUrl,
        cancelUrl,
      }
    );

    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
      return;
    }

    useAlert(t('BILLING_SETTINGS.TOPUP.PURCHASE_ERROR'));
  } catch (error) {
    const errorMessage =
      error.response?.data?.error || t('BILLING_SETTINGS.TOPUP.PURCHASE_ERROR');
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :description="dialogDescription"
    :width="dialogWidth"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <template v-if="currentStep === 'select'">
      <div class="grid grid-cols-2 gap-4">
        <CreditPackageCard
          v-for="option in TOPUP_OPTIONS"
          :key="option.credits"
          name="credit-package"
          :credits="option.credits"
          :amount="option.amount"
          :currency="option.currency"
          :is-popular="option.credits === POPULAR_CREDITS_AMOUNT"
          :is-selected="selectedCredits === option.credits"
          @select="handlePackageSelect(option.credits)"
        />
      </div>

      <div class="p-4 mt-6 rounded-lg bg-n-solid-2 border border-n-weak">
        <p class="text-sm text-n-slate-11">
          <span class="font-semibold text-n-slate-12">{{
            $t('BILLING_SETTINGS.TOPUP.NOTE_TITLE')
          }}</span>
          {{ $t('BILLING_SETTINGS.TOPUP.NOTE_DESCRIPTION') }}
        </p>
      </div>
    </template>

    <template v-else>
      <div class="flex flex-col gap-4">
        <p class="text-sm text-n-slate-11">
          {{
            $t('BILLING_SETTINGS.TOPUP.CONFIRM.DESCRIPTION', {
              credits: formattedCredits,
              amount: formattedAmount,
            })
          }}
        </p>
      </div>
    </template>

    <template #footer>
      <div class="flex justify-end gap-2 w-full">
        <template v-if="currentStep === 'select'">
          <Button
            slate
            faded
            :label="$t('BILLING_SETTINGS.TOPUP.CANCEL')"
            @click="close"
          />
          <Button
            solid
            blue
            :label="$t('BILLING_SETTINGS.TOPUP.CONFIRM.CONFIRM_PURCHASE')"
            :disabled="!selectedOption"
            @click="goToConfirmStep"
          />
        </template>
        <template v-else>
          <Button
            slate
            faded
            :label="$t('BILLING_SETTINGS.TOPUP.CONFIRM.GO_BACK')"
            @click="goBackToSelectStep"
          />
          <Button
            solid
            blue
            :label="$t('BILLING_SETTINGS.TOPUP.PURCHASE')"
            :is-loading="isLoading"
            @click="handlePurchase"
          />
        </template>
      </div>
    </template>
  </Dialog>
</template>
