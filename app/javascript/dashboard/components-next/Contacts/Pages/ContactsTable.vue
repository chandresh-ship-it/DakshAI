<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contacts: { type: Array, required: true },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
  visibleColumns: {
    type: Array,
    default: () => [
      'email',
      'phoneNumber',
      'company',
      'createdAt',
      'lastActivity',
      'tags',
    ],
  },
});

const emit = defineEmits(['toggleContact', 'toggleAll']);

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const hoveredRowId = ref(null);

const customAttributes = useMapGetter('attributes/getContactAttributes');

const selectedIdsSet = computed(() => new Set(props.selectedContactIds || []));

const isAllSelected = computed(() => {
  if (!props.contacts.length) return false;
  return props.contacts.every(c => selectedIdsSet.value.has(c.id));
});

const isSomeSelected = computed(() => {
  if (!props.contacts.length) return false;
  return (
    props.contacts.some(c => selectedIdsSet.value.has(c.id)) &&
    !isAllSelected.value
  );
});

const handleSelectAll = event => {
  emit('toggleAll', event.target.checked);
};

const handleSelectRow = (id, event) => {
  emit('toggleContact', { id, value: event.target.checked });
};

const isSelected = id => selectedIdsSet.value.has(id);

const parseDateString = dateString => {
  if (!dateString) return null;
  const isUnixTimestamp =
    typeof dateString === 'number' ||
    (!isNaN(dateString) &&
      !String(dateString).includes('-') &&
      !String(dateString).includes('T'));
  return new Date(isUnixTimestamp ? Number(dateString) * 1000 : dateString);
};

const formatDate = dateString => {
  const date = parseDateString(dateString);
  if (!date) return '';
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

const getRelativeTime = dateString => {
  const date = parseDateString(dateString);
  if (!date) return '';
  const diffMs = new Date() - date;
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}d ago`;
};

const onClickViewDetails = async id => {
  const routeTypes = {
    contacts_dashboard_segments_index: ['contacts_edit_segment', 'segmentId'],
    contacts_dashboard_labels_index: ['contacts_edit_label', 'label'],
  };
  const [name, paramKey] = routeTypes[route.name] || ['contacts_edit'];
  const params = {
    contactId: id,
    ...(paramKey && { [paramKey]: route.params[paramKey] }),
  };

  await router.push({ name, params, query: route.query });
};

const visibleCustomColumns = computed(() => {
  return props.visibleColumns
    .filter(key => key.startsWith('custom_'))
    .map(key => {
      const attributeKey = key.replace('custom_', '');
      const attr = (customAttributes.value || []).find(
        a => a.attributeKey === attributeKey
      );
      return {
        key,
        attributeKey,
        label: attr
          ? attr.attributeDisplayName || attr.attributeKey
          : attributeKey,
      };
    });
});
</script>

<template>
  <div
    class="w-full overflow-x-auto border rounded-lg border-n-slate-4 bg-n-surface-1"
  >
    <table class="w-full text-left border-collapse table-auto">
      <thead>
        <tr
          class="border-b border-n-slate-4 bg-n-slate-2 text-n-slate-11 text-xs font-semibold uppercase tracking-wider"
        >
          <th class="p-3 w-10 text-center">
            <Checkbox
              :model-value="isAllSelected"
              :indeterminate="isSomeSelected"
              @change="handleSelectAll"
            />
          </th>
          <th class="p-3 text-sm font-semibold capitalize text-n-slate-12">
            {{ t('CONTACTS_LAYOUT.FILTER.NAME') }}
          </th>
          <th
            v-if="visibleColumns.includes('email')"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.EMAIL') }}
          </th>
          <th
            v-if="visibleColumns.includes('phoneNumber')"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.PHONE_NUMBER') }}
          </th>
          <th
            v-if="visibleColumns.includes('company')"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.COMPANY') }}
          </th>
          <th
            v-if="visibleColumns.includes('createdAt')"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.CREATED_AT') }}
          </th>
          <th
            v-if="visibleColumns.includes('lastActivity')"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.LAST_ACTIVITY') }}
          </th>
          <th
            v-if="visibleColumns.includes('tags')"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ t('CONTACTS_LAYOUT.FILTER.TAGS') }}
          </th>
          <th
            v-for="col in visibleCustomColumns"
            :key="col.key"
            class="p-3 text-sm font-semibold capitalize text-n-slate-12"
          >
            {{ col.label }}
          </th>
          <th class="p-3 w-12 text-center" />
        </tr>
      </thead>
      <tbody class="divide-y divide-n-slate-3">
        <tr
          v-for="contact in contacts"
          :key="contact.id"
          class="hover:bg-n-slate-2 transition-colors cursor-pointer text-sm text-n-slate-12"
          :class="{ 'bg-n-slate-3': isSelected(contact.id) }"
          @click="onClickViewDetails(contact.id)"
          @mouseenter="hoveredRowId = contact.id"
          @mouseleave="hoveredRowId = null"
        >
          <!-- Checkbox -->
          <td class="p-3 text-center" @click.stop>
            <Checkbox
              :model-value="isSelected(contact.id)"
              @change="event => handleSelectRow(contact.id, event)"
            />
          </td>

          <!-- Name & Avatar -->
          <td class="p-3 font-medium flex items-center gap-3">
            <Avatar
              :name="contact.name"
              :src="contact.thumbnail"
              :size="32"
              hide-offline-status
            />
            <div class="flex flex-col">
              <span
                class="font-medium text-n-slate-12 hover:text-n-brand transition-colors"
              >
                {{ contact.name || 'Unnamed Contact' }}
              </span>
            </div>
          </td>

          <!-- Email -->
          <td
            v-if="visibleColumns.includes('email')"
            class="p-3 text-n-slate-11 font-mono text-xs"
          >
            {{ contact.email || '-' }}
          </td>

          <!-- Phone -->
          <td
            v-if="visibleColumns.includes('phoneNumber')"
            class="p-3 text-n-slate-11"
          >
            {{ contact.phoneNumber || '-' }}
          </td>

          <!-- Company -->
          <td
            v-if="visibleColumns.includes('company')"
            class="p-3 text-n-slate-11"
          >
            {{ contact.additionalAttributes?.companyName || '-' }}
          </td>

          <!-- Created -->
          <td
            v-if="visibleColumns.includes('createdAt')"
            class="p-3 text-n-slate-11"
          >
            {{ formatDate(contact.createdAt) }}
          </td>

          <!-- Last Activity -->
          <td
            v-if="visibleColumns.includes('lastActivity')"
            class="p-3 text-n-slate-11"
          >
            <span class="inline-flex items-center gap-1.5">
              <span class="i-lucide-message-square size-3.5 text-n-brand" />
              {{ getRelativeTime(contact.lastActivityAt) || '-' }}
            </span>
          </td>

          <!-- Tags -->
          <td v-if="visibleColumns.includes('tags')" class="p-3">
            <div class="flex flex-wrap gap-1 max-w-[12rem]">
              <span
                v-for="label in (contact.labels || []).slice(0, 3)"
                :key="label"
                class="px-2 py-0.5 text-xs rounded-full bg-n-slate-3 text-n-slate-12 font-medium"
              >
                {{ label }}
              </span>
              <span
                v-if="(contact.labels || []).length > 3"
                class="px-2 py-0.5 text-xs rounded-full bg-n-slate-4 text-n-slate-11 font-medium"
              >
                +{{ contact.labels.length - 3 }}
              </span>
            </div>
          </td>

          <!-- Custom Attributes columns -->
          <td
            v-for="col in visibleCustomColumns"
            :key="col.key"
            class="p-3 text-n-slate-11"
          >
            {{ contact.customAttributes?.[col.attributeKey] || '-' }}
          </td>

          <!-- Row actions -->
          <td class="p-3 text-center" @click.stop>
            <div
              v-show="hoveredRowId === contact.id"
              class="flex items-center justify-center"
            >
              <Button
                icon="i-lucide-chevron-right"
                variant="ghost"
                color="slate"
                size="xs"
                @click="onClickViewDetails(contact.id)"
              />
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
