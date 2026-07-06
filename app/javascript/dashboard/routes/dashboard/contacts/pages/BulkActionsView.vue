<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import BulkActionAuditsAPI from 'dashboard/api/bulkActionAudits';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const audits = ref([]);
const isLoading = ref(false);

const statusFilter = ref('');
const operationFilter = ref('');
const dateFromFilter = ref('');
const dateToFilter = ref('');

const fetchAudits = async () => {
  isLoading.value = true;
  try {
    const params = {};
    if (statusFilter.value) {
      params.status = statusFilter.value;
    }
    if (operationFilter.value) {
      params.operation_type = operationFilter.value;
    }

    const response = await BulkActionAuditsAPI.get(params);
    let data = response.data || [];

    // Local filtering for Date Range
    if (dateFromFilter.value) {
      const fromDate = new Date(dateFromFilter.value);
      data = data.filter(audit => new Date(audit.created_at) >= fromDate);
    }
    if (dateToFilter.value) {
      const toDate = new Date(dateToFilter.value);
      toDate.setHours(23, 59, 59, 999);
      data = data.filter(audit => new Date(audit.created_at) <= toDate);
    }

    audits.value = data;
  } catch (error) {
    // Ignore error
  } finally {
    isLoading.value = false;
  }
};

const clearFilters = () => {
  statusFilter.value = '';
  operationFilter.value = '';
  dateFromFilter.value = '';
  dateToFilter.value = '';
  fetchAudits();
};

const formatDate = dateString => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const getStatusClass = status => {
  const classes = {
    pending: 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-500',
    processing: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-500',
    completed: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-500',
    failed: 'bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-500',
  };
  return classes[status] || 'bg-slate-100 text-slate-800';
};

const getOperationLabel = operation => {
  const labels = {
    add_tag: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.ADD_LABEL'),
    remove_tag: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.REMOVE_LABEL'),
    delete: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.DELETE'),
    send_sms: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_SMS'),
    send_email: t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_EMAIL'),
  };
  return labels[operation] || operation;
};

const formatStatistics = audit => {
  if (audit.status === 'pending') return t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING');
  if (audit.status === 'processing' && !audit.statistics?.total) return t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING');

  const stats = audit.statistics || {};
  const total = stats.total || 0;
  const success = stats.success || 0;

  if (total === 0) return '-';
  return `${success} / ${total} succeeded`;
};

watch([statusFilter, operationFilter, dateFromFilter, dateToFilter], () => {
  fetchAudits();
});

onMounted(() => {
  fetchAudits();
});
</script>

<template>
  <div class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-surface-1 p-6">
    <!-- Header -->
    <div class="flex flex-col mb-6">
      <h1 class="text-2xl font-semibold text-n-slate-12">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.SUBTITLE') }}
      </p>
    </div>

    <!-- Filters Row -->
    <div class="flex flex-wrap items-center gap-3 mb-6 bg-n-slate-2 p-3 rounded-lg border border-n-slate-4">
      <!-- Status Filter -->
      <select
        v-model="statusFilter"
        class="px-3 py-1.5 text-sm rounded-lg border border-n-slate-4 bg-n-surface-1 text-n-slate-12 focus:outline-none focus:border-n-brand"
      >
        <option value="">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.STATUS') }}</option>
        <option value="pending">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING') }}</option>
        <option value="processing">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING') }}</option>
        <option value="completed">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.COMPLETED') }}</option>
        <option value="failed">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.FAILED') }}</option>
      </select>

      <!-- Operation Filter -->
      <select
        v-model="operationFilter"
        class="px-3 py-1.5 text-sm rounded-lg border border-n-slate-4 bg-n-surface-1 text-n-slate-12 focus:outline-none focus:border-n-brand"
      >
        <option value="">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.OPERATION') }}</option>
        <option value="add_tag">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.ADD_LABEL') }}</option>
        <option value="remove_tag">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.REMOVE_LABEL') }}</option>
        <option value="delete">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.DELETE') }}</option>
        <option value="send_sms">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_SMS') }}</option>
        <option value="send_email">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_EMAIL') }}</option>
      </select>

      <!-- Date Range -->
      <div class="flex items-center gap-2">
        <span class="text-xs text-n-slate-11 font-medium">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.DATE_FROM') }}:</span>
        <input
          v-model="dateFromFilter"
          type="date"
          class="px-3 py-1.5 text-sm rounded-lg border border-n-slate-4 bg-n-surface-1 text-n-slate-12 focus:outline-none focus:border-n-brand"
        />
      </div>

      <div class="flex items-center gap-2">
        <span class="text-xs text-n-slate-11 font-medium">{{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.DATE_TO') }}:</span>
        <input
          v-model="dateToFilter"
          type="date"
          class="px-3 py-1.5 text-sm rounded-lg border border-n-slate-4 bg-n-surface-1 text-n-slate-12 focus:outline-none focus:border-n-brand"
        />
      </div>

      <!-- Clear Button -->
      <Button
        v-if="statusFilter || operationFilter || dateFromFilter || dateToFilter"
        label="Clear Filters"
        variant="ghost"
        color="slate"
        size="sm"
        @click="clearFilters"
      />
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center py-20 text-n-slate-11">
      <Spinner />
    </div>

    <!-- Empty State -->
    <div
      v-else-if="!audits.length"
      class="flex flex-col items-center justify-center py-20 border border-dashed rounded-lg border-n-slate-4 bg-n-slate-2"
    >
      <span class="i-lucide-activity size-12 text-n-slate-8 mb-4" />
      <h3 class="text-lg font-medium text-n-slate-12 mb-1">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.EMPTY.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11 text-center max-w-sm">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.EMPTY.SUBTITLE') }}
      </p>
    </div>

    <!-- Table Grid -->
    <div v-else class="w-full border rounded-lg border-n-slate-4 bg-n-surface-1 overflow-x-auto">
      <table class="w-full text-left border-collapse table-auto">
        <thead>
          <tr class="border-b border-n-slate-4 bg-n-slate-2 text-n-slate-11 text-xs font-semibold uppercase tracking-wider">
            <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.ACTION_NAME') }}
            </th>
            <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.OPERATION') }}
            </th>
            <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.CREATED_AT') }}
            </th>
            <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.COMPLETED_AT') }}
            </th>
            <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.STATUS') }}
            </th>
            <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
              {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.STATISTICS') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-slate-3 text-sm text-n-slate-12">
          <tr v-for="audit in audits" :key="audit.id" class="hover:bg-n-slate-2 transition-colors">
            <!-- Action Name -->
            <td class="p-3 font-medium text-n-slate-12">
              {{ audit.action_label }}
            </td>
            <!-- Operation -->
            <td class="p-3">
              <span class="px-2 py-0.5 text-xs rounded-full bg-n-slate-3 text-n-slate-11 font-medium border border-n-slate-4">
                {{ getOperationLabel(audit.operation_type) }}
              </span>
            </td>
            <!-- Created At -->
            <td class="p-3 text-n-slate-11 font-mono text-xs">
              {{ formatDate(audit.created_at) }}
            </td>
            <!-- Completed At -->
            <td class="p-3 text-n-slate-11 font-mono text-xs">
              {{ formatDate(audit.completed_at) }}
            </td>
            <!-- Status -->
            <td class="p-3">
              <span :class="getStatusClass(audit.status)" class="px-2.5 py-0.5 text-xs rounded-full font-medium inline-block uppercase tracking-wider text-center min-w-[5rem]">
                {{ t(`CONTACTS_BULK_ACTIONS.AUDIT.STATUS.${audit.status.toUpperCase()}`) }}
              </span>
            </td>
            <!-- Statistics -->
            <td class="p-3 text-n-slate-11 font-medium">
              {{ formatStatistics(audit) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
