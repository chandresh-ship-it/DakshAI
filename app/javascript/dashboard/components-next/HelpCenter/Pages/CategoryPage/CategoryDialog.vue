<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CategoryForm from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryForm.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'edit',
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCategory: {
    type: Object,
    default: () => ({}),
  },
  portalName: {
    type: String,
    default: '',
  },
  activeLocaleName: {
    type: String,
    default: '',
  },
  activeLocaleCode: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const dialogRef = ref(null);
const categoryFormRef = ref(null);
const isUpdating = ref(false);

const isInvalidForm = computed(() => {
  if (!categoryFormRef.value) return false;
  const { isSubmitDisabled } = categoryFormRef.value;
  return isSubmitDisabled;
});

const handleCategory = async () => {
  if (!categoryFormRef.value) return;
  const { state } = categoryFormRef.value;
  const { id, name, slug, icon, description, locale } = state;
  const categoryData = { name, icon, slug, description };

  if (props.mode === 'create') {
    categoryData.locale = locale;
  } else {
    categoryData.id = id;
  }

  try {
    isUpdating.value = true;
    const action = props.mode === 'edit' ? 'update' : 'create';
    const payload = {
      portalSlug: route.params.portalSlug,
      categoryObj: categoryData,
    };

    if (action === 'update') {
      payload.categoryId = id;
    }

    await store.dispatch(`categories/${action}`, payload);

    const successMessage = t(
      `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.${props.mode.toUpperCase()}.API.SUCCESS_MESSAGE`
    );
    useAlert(successMessage);

    const trackEvent =
      props.mode === 'edit'
        ? PORTALS_EVENTS.EDIT_CATEGORY
        : PORTALS_EVENTS.CREATE_CATEGORY;
    useTrack(
      trackEvent,
      props.mode === 'create'
        ? { hasDescription: Boolean(description) }
        : undefined
    );

    dialogRef.value?.close();
  } catch (error) {
    const errorMessage =
      error?.message ||
      t(
        `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.${props.mode.toUpperCase()}.API.ERROR_MESSAGE`
      );
    useAlert(errorMessage);
  } finally {
    isUpdating.value = false;
  }
};

const handleClose = () => {
  emit('close');
};

onMounted(() => {
  dialogRef.value?.open();
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="
      t(
        `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.${mode.toUpperCase()}`
      )
    "
    :description="
      t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.DESCRIPTION')
    "
    :is-loading="isUpdating"
    :disable-confirm-button="isUpdating || isInvalidForm"
    @confirm="handleCategory"
    @close="handleClose"
  >
    <CategoryForm
      ref="categoryFormRef"
      :mode="mode"
      :selected-category="selectedCategory"
      :active-locale-code="activeLocaleCode"
      :portal-name="portalName"
      :active-locale-name="activeLocaleName"
      :show-action-buttons="false"
    />
  </Dialog>
</template>
