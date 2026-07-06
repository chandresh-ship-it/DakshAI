<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  visibleColumns: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:visibleColumns']);

const { t } = useI18n();
const customAttributes = useMapGetter('attributes/getContactAttributes');

const standardColumns = [
  { key: 'email', label: t('CONTACTS_LAYOUT.FILTER.EMAIL') },
  { key: 'phoneNumber', label: t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER') },
  { key: 'company', label: t('CONTACTS_LAYOUT.FILTER.COMPANY') },
  { key: 'createdAt', label: t('CONTACTS_LAYOUT.FILTER.CREATED_AT') },
  { key: 'lastActivity', label: t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY') },
  { key: 'tags', label: t('CONTACTS_LAYOUT.FILTER.TAGS') },
];

const allColumns = computed(() => {
  const dynamicCols = (customAttributes.value || []).map(attr => ({
    key: `custom_${attr.attributeKey}`,
    label: attr.attributeDisplayName || attr.attributeKey,
  }));
  return [...standardColumns, ...dynamicCols];
});

const toggleColumn = (key, checked) => {
  let updated = [...props.visibleColumns];
  if (checked) {
    if (!updated.includes(key)) updated.push(key);
  } else {
    updated = updated.filter(c => c !== key);
  }
  emit('update:visibleColumns', updated);
};
</script>

<template>
  <div class="p-4 w-60 max-h-96 flex flex-col gap-2 bg-n-surface-1">
    <div
      class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider mb-2"
    >
      {{ t('CONTACTS_LAYOUT.FILTER.MANAGE_COLUMNS') }}
    </div>
    <div class="flex flex-col gap-2.5 overflow-y-auto">
      <label
        class="flex items-center gap-2 text-sm text-n-slate-12 cursor-not-allowed opacity-70"
      >
        <Checkbox disabled model-value />
        <span>{{ t('CONTACTS_LAYOUT.FILTER.NAME') }}</span>
      </label>

      <label
        v-for="col in allColumns"
        :key="col.key"
        class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer hover:text-n-slate-12"
      >
        <Checkbox
          :model-value="visibleColumns.includes(col.key)"
          @change="event => toggleColumn(col.key, event.target.checked)"
        />
        <span>{{ col.label }}</span>
      </label>
    </div>
  </div>
</template>
