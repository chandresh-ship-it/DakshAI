<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import BulkActionAuditsAPI from 'dashboard/api/bulkActionAudits';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { RelayButton } from 'dashboard/components-next/relay';

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
  } catch {
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

const hasFilters = () =>
  statusFilter.value ||
  operationFilter.value ||
  dateFromFilter.value ||
  dateToFilter.value;

const formatDate = dateString => {
  if (!dateString) return '—';
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
    pending: 'bg-amber-500/10 text-amber-700 dark:text-amber-400',
    processing: 'bg-primary/10 text-primary',
    completed: 'bg-emerald-500/10 text-emerald-700 dark:text-emerald-400',
    failed: 'bg-destructive/10 text-destructive',
  };
  return classes[status] || 'bg-muted text-muted-foreground';
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
  if (audit.status === 'pending')
    return t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING');
  if (audit.status === 'processing' && !audit.statistics?.total)
    return t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING');

  const stats = audit.statistics || {};
  const total = stats.total || 0;
  const success = stats.success || 0;

  if (total === 0) return '—';
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
  <div class="flex h-full flex-1 flex-col overflow-auto bg-background p-6">
    <div class="mb-10 max-w-6xl">
      <h2 class="text-base font-semibold tracking-tight text-foreground">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TITLE') }}
      </h2>
      <p class="mt-1 text-[14px] text-muted-foreground">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.SUBTITLE') }}
      </p>
    </div>

    <div
      class="mb-10 max-w-6xl space-y-6 rounded-xl border border-border bg-card p-6 shadow-sm"
    >
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <select
          v-model="statusFilter"
          class="h-11 w-full rounded-md border border-border bg-background px-4 text-[14px] font-medium text-foreground focus:outline-none focus:ring-1 focus:ring-primary/30"
        >
          <option value="">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.STATUS') }}
          </option>
          <option value="pending">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PENDING') }}
          </option>
          <option value="processing">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.PROCESSING') }}
          </option>
          <option value="completed">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.COMPLETED') }}
          </option>
          <option value="failed">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.STATUS.FAILED') }}
          </option>
        </select>

        <select
          v-model="operationFilter"
          class="h-11 w-full rounded-md border border-border bg-background px-4 text-[14px] font-medium text-foreground focus:outline-none focus:ring-1 focus:ring-primary/30"
        >
          <option value="">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.OPERATION') }}
          </option>
          <option value="add_tag">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.ADD_LABEL') }}
          </option>
          <option value="remove_tag">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.REMOVE_LABEL') }}
          </option>
          <option value="delete">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.DELETE') }}
          </option>
          <option value="send_sms">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_SMS') }}
          </option>
          <option value="send_email">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.OPERATION.SEND_EMAIL') }}
          </option>
        </select>
      </div>

      <div class="flex flex-wrap items-end gap-4">
        <div class="flex flex-col gap-1.5">
          <span class="text-xs font-semibold text-muted-foreground">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.DATE_FROM') }}
          </span>
          <input
            v-model="dateFromFilter"
            type="date"
            class="h-[38px] w-[180px] rounded-md border border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm focus:outline-none focus:ring-1 focus:ring-primary/30"
          />
        </div>
        <span class="i-lucide-arrow-right mb-2 size-4 text-muted-foreground" />
        <div class="flex flex-col gap-1.5">
          <span class="text-xs font-semibold text-muted-foreground">
            {{ t('CONTACTS_BULK_ACTIONS.AUDIT.FILTER.DATE_TO') }}
          </span>
          <input
            v-model="dateToFilter"
            type="date"
            class="h-[38px] w-[180px] rounded-md border border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm focus:outline-none focus:ring-1 focus:ring-primary/30"
          />
        </div>
        <RelayButton
          v-if="hasFilters()"
          variant="ghost"
          size="sm"
          class="mb-0.5"
          @click="clearFilters"
        >
          {{ t('CONTACTS_LAYOUT.FILTER.ACTIVE_FILTERS.CLEAR_FILTERS') }}
        </RelayButton>
      </div>
    </div>

    <div
      v-if="isLoading"
      class="flex items-center justify-center py-20 text-muted-foreground"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!audits.length"
      class="flex max-w-6xl flex-col items-center justify-center rounded-xl border border-dashed border-border bg-muted/20 py-20"
    >
      <span class="i-lucide-activity mb-4 size-12 text-muted-foreground/50" />
      <h3 class="mb-1 text-lg font-medium text-foreground">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.EMPTY.TITLE') }}
      </h3>
      <p class="max-w-sm text-center text-sm text-muted-foreground">
        {{ t('CONTACTS_BULK_ACTIONS.AUDIT.EMPTY.SUBTITLE') }}
      </p>
    </div>

    <div
      v-else
      class="max-w-6xl overflow-hidden rounded-xl border border-border/50 bg-card shadow-sm"
    >
      <div class="w-full overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead class="border-b border-border/50 bg-muted/30">
            <tr>
              <th class="px-4 py-3 font-medium text-muted-foreground">
                {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.ACTION_NAME') }}
              </th>
              <th class="px-4 py-3 font-medium text-muted-foreground">
                {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.OPERATION') }}
              </th>
              <th class="px-4 py-3 font-medium text-muted-foreground">
                {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.CREATED_AT') }}
              </th>
              <th class="px-4 py-3 font-medium text-muted-foreground">
                {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.COMPLETED_AT') }}
              </th>
              <th class="px-4 py-3 font-medium text-muted-foreground">
                {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.STATUS') }}
              </th>
              <th class="px-4 py-3 font-medium text-muted-foreground">
                {{ t('CONTACTS_BULK_ACTIONS.AUDIT.TABLE.STATISTICS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border/40">
            <tr
              v-for="audit in audits"
              :key="audit.id"
              class="transition-colors hover:bg-muted/30"
            >
              <td class="px-4 py-4 font-medium text-foreground">
                {{ audit.action_label }}
              </td>
              <td class="px-4 py-4">
                <span
                  class="inline-flex items-center rounded-md border border-border/50 bg-muted px-2 py-0.5 text-[11px] font-medium text-muted-foreground"
                >
                  {{ getOperationLabel(audit.operation_type) }}
                </span>
              </td>
              <td class="px-4 py-4 text-sm text-muted-foreground">
                {{ formatDate(audit.created_at) }}
              </td>
              <td class="px-4 py-4 text-sm text-muted-foreground">
                {{ formatDate(audit.completed_at) }}
              </td>
              <td class="px-4 py-4">
                <span
                  :class="getStatusClass(audit.status)"
                  class="inline-block min-w-[5rem] rounded-full px-2.5 py-0.5 text-center text-xs font-medium uppercase tracking-wider"
                >
                  {{
                    t(
                      `CONTACTS_BULK_ACTIONS.AUDIT.STATUS.${audit.status.toUpperCase()}`
                    )
                  }}
                </span>
              </td>
              <td class="px-4 py-4 text-sm font-medium text-muted-foreground">
                {{ formatStatistics(audit) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
