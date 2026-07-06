<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const audits = ref([]);
const isLoading = ref(false);
</script>

<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.HEADER.SUB_NAV.BULK_ACTIONS') }}
      </h1>
    </div>
    
    <div class="flex flex-col items-center justify-center py-20 border border-dashed rounded-lg border-n-slate-5 bg-n-slate-2">
      <span class="i-lucide-activity size-12 text-n-slate-8 mb-4" />
      <h3 class="text-lg font-medium text-n-slate-12 mb-1">No bulk actions audit logs</h3>
      <p class="text-sm text-n-slate-11 text-center max-w-sm">
        When you run batch updates or deletions, they will be logged and audited here.
      </p>
    </div>
  </div>
</template>
