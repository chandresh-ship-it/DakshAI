<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import {
  RelayBadge,
  RelayButton,
  RelayCheckbox,
  RelayInput,
  RelayLabel,
} from 'dashboard/components-next/relay';
import TasksAPI from 'dashboard/api/tasks';

const { t } = useI18n();
const store = useStore();

const tasks = ref([]);
const isFetching = ref(false);
const searchQuery = ref('');
const activeTab = ref('all');
const openFilter = ref(null);
const openTaskMenu = ref(null);

const assigneeFilter = ref('any');
const statusFilter = ref('all');
const dueDateFilter = ref('any');

const taskDialogRef = ref(null);
const editingTask = ref(null);
const taskForm = ref({
  title: '',
  description: '',
  assigneeId: '',
  contactId: '',
  dueDate: '',
});

const agents = useMapGetter('agents/getAgents');
const contacts = useMapGetter('contacts/getContactsList');

const timeframeTabs = computed(() => [
  { value: 'all', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_ALL') },
  { value: 'today', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_TODAY') },
  { value: 'overdue', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_OVERDUE') },
  { value: 'upcoming', label: t('CONTACTS_LAYOUT.TASKS_VIEW.TAB_UPCOMING') },
]);

const assigneeFilterOptions = computed(() => [
  {
    value: 'any',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_ANY'),
  },
  {
    value: 'unassigned',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_UNASSIGNED'),
  },
  ...(agents.value || []).map(agent => ({
    value: agent.id.toString(),
    label: agent.name,
  })),
]);

const statusFilterOptions = computed(() => [
  { value: 'all', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_ALL') },
  {
    value: 'pending',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_PENDING'),
  },
  {
    value: 'completed',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_COMPLETED'),
  },
]);

const dueDateFilterOptions = computed(() => [
  { value: 'any', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_ANY') },
  { value: 'today', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_TODAY') },
  {
    value: 'tomorrow',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_TOMORROW'),
  },
  { value: 'week', label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_WEEK') },
]);

const agentOptions = computed(() => [
  {
    value: '',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_UNASSIGNED'),
  },
  ...(agents.value || []).map(agent => ({
    value: agent.id.toString(),
    label: agent.name,
  })),
]);

const contactOptions = computed(() => [
  {
    value: '',
    label: t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CONTACT_PLACEHOLDER'),
  },
  ...(contacts.value || []).map(contact => ({
    value: contact.id.toString(),
    label:
      contact.name ||
      contact.email ||
      t('CONTACTS_LAYOUT.CARD.UNNAMED_CONTACT'),
  })),
]);

const assigneeFilterLabel = computed(() => {
  const selected = assigneeFilterOptions.value.find(
    option => option.value === assigneeFilter.value
  );
  return selected?.label || assigneeFilterOptions.value[0].label;
});

const statusFilterLabel = computed(() => {
  const selected = statusFilterOptions.value.find(
    option => option.value === statusFilter.value
  );
  return selected?.label || statusFilterOptions.value[0].label;
});

const dueDateFilterLabel = computed(() => {
  const selected = dueDateFilterOptions.value.find(
    option => option.value === dueDateFilter.value
  );
  return selected?.label || dueDateFilterOptions.value[0].label;
});

const startOfDay = date => {
  const next = new Date(date);
  next.setHours(0, 0, 0, 0);
  return next;
};

const endOfDay = date => {
  const next = new Date(date);
  next.setHours(23, 59, 59, 999);
  return next;
};

const matchesClientDueDate = task => {
  if (dueDateFilter.value === 'any') return true;
  if (!task.due_at) return false;

  const due = new Date(task.due_at);
  const today = startOfDay(new Date());

  if (dueDateFilter.value === 'today') {
    return due >= today && due <= endOfDay(today);
  }

  if (dueDateFilter.value === 'tomorrow') {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return due >= tomorrow && due <= endOfDay(tomorrow);
  }

  if (dueDateFilter.value === 'week') {
    const weekEnd = new Date(today);
    weekEnd.setDate(weekEnd.getDate() + 7);
    return due >= today && due <= endOfDay(weekEnd);
  }

  return true;
};

const displayedTasks = computed(() =>
  tasks.value.filter(task => {
    if (assigneeFilter.value === 'unassigned' && task.assignee_id) {
      return false;
    }
    return matchesClientDueDate(task);
  })
);

const getAgentName = id => {
  if (!id) return '';
  const agent = (agents.value || []).find(
    item => item.id.toString() === id.toString()
  );
  return agent ? agent.name : '';
};

const getAgentOptionLabel = value => {
  const option = agentOptions.value.find(item => item.value === value);
  return option?.label || agentOptions.value[0].label;
};

const getContactOptionLabel = value => {
  const option = contactOptions.value.find(item => item.value === value);
  return option?.label || contactOptions.value[0].label;
};

const formatDate = dateString => {
  if (!dateString) return '';
  return new Date(dateString).toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const isOverdue = task => {
  if (task.completed || !task.due_at) return false;
  return new Date(task.due_at) < new Date();
};

const statusLabelFor = task =>
  task.completed
    ? t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_COMPLETED')
    : t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_PENDING');

const closeMenus = () => {
  openFilter.value = null;
  openTaskMenu.value = null;
};

const toggleFilter = key => {
  openFilter.value = openFilter.value === key ? null : key;
  openTaskMenu.value = null;
};

const toggleTaskMenu = id => {
  openTaskMenu.value = openTaskMenu.value === id ? null : id;
  openFilter.value = null;
};

const fetchTasks = async () => {
  isFetching.value = true;
  try {
    const params = {
      q: searchQuery.value || undefined,
    };

    if (activeTab.value !== 'all') {
      params.due_filter = activeTab.value;
    } else if (dueDateFilter.value === 'today') {
      params.due_filter = 'today';
    }

    if (
      assigneeFilter.value !== 'any' &&
      assigneeFilter.value !== 'unassigned'
    ) {
      params.assignee_id = assigneeFilter.value;
    }

    if (statusFilter.value !== 'all') {
      params.completed = statusFilter.value === 'completed';
    }

    const response = await TasksAPI.get(params);
    tasks.value = response.data || [];
  } catch {
    // Ignore error
  } finally {
    isFetching.value = false;
  }
};

const setTab = tab => {
  activeTab.value = tab;
  if (tab !== 'all') {
    dueDateFilter.value = 'any';
  }
  fetchTasks();
};

const selectAssignee = value => {
  assigneeFilter.value = value;
  closeMenus();
};

const selectStatus = value => {
  statusFilter.value = value;
  closeMenus();
};

const selectDueDate = value => {
  dueDateFilter.value = value;
  if (value !== 'any') {
    activeTab.value = 'all';
  }
  closeMenus();
  fetchTasks();
};

const setTaskCompleted = async (task, completed) => {
  const originalVal = task.completed;
  task.completed = completed;
  try {
    await TasksAPI.update(task.id, { task: { completed } });
  } catch {
    task.completed = originalVal;
  }
};

const openAddTaskDialog = () => {
  editingTask.value = null;
  taskForm.value = {
    title: '',
    description: '',
    assigneeId: '',
    contactId: '',
    dueDate: '',
  };
  closeMenus();
  taskDialogRef.value.open();
};

const openEditTaskDialog = task => {
  editingTask.value = task;
  taskForm.value = {
    title: task.title,
    description: task.description || '',
    assigneeId: task.assignee_id ? task.assignee_id.toString() : '',
    contactId: task.contacts?.[0]?.id ? task.contacts[0].id.toString() : '',
    dueDate: task.due_at ? task.due_at.slice(0, 16) : '',
  };
  closeMenus();
  taskDialogRef.value.open();
};

const handleDeleteTask = async id => {
  closeMenus();
  if (!window.confirm(t('CONTACTS_LAYOUT.TASKS_VIEW.DELETE_CONFIRM'))) return;
  try {
    await TasksAPI.delete(id);
    tasks.value = tasks.value.filter(taskItem => taskItem.id !== id);
  } catch {
    // Ignore error
  }
};

const handleSaveTask = async () => {
  const payload = {
    task: {
      title: taskForm.value.title,
      description: taskForm.value.description,
      assignee_id: taskForm.value.assigneeId || null,
      due_at: taskForm.value.dueDate || null,
      contact_ids: taskForm.value.contactId
        ? [Number(taskForm.value.contactId)]
        : [],
    },
  };

  try {
    if (editingTask.value) {
      await TasksAPI.update(editingTask.value.id, payload);
    } else {
      await TasksAPI.create(payload);
    }
    fetchTasks();
    taskDialogRef.value.close();
  } catch {
    // Ignore error
  }
};

watch([assigneeFilter, statusFilter], () => {
  fetchTasks();
});

watch(searchQuery, () => {
  fetchTasks();
});

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('contacts/get', { page: 1 });
  fetchTasks();
});
</script>

<template>
  <div
    v-on-click-outside="closeMenus"
    class="relative flex h-full flex-1 flex-col overflow-y-auto bg-background p-6"
  >
    <div class="w-full">
      <!-- Header -->
      <div class="mb-6 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <h2 class="text-base font-semibold tracking-tight text-foreground">
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.TITLE') }}
          </h2>
          <RelayBadge
            class="rounded-full bg-primary px-2.5 py-0.5 text-xs font-semibold text-primary-foreground hover:bg-primary/90"
          >
            {{
              t('CONTACTS_LAYOUT.TASKS_VIEW.TASKS_COUNT', {
                count: displayedTasks.length,
              })
            }}
          </RelayBadge>
        </div>
        <RelayButton
          class="h-9 gap-1.5 rounded-lg px-4 text-sm font-medium shadow-sm"
          @click="openAddTaskDialog"
        >
          <span class="i-lucide-plus size-4" />
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_TASK') }}
        </RelayButton>
      </div>

      <!-- Timeframe tabs -->
      <div class="mb-4 border-b border-border/60">
        <div class="flex items-center gap-6">
          <button
            v-for="tab in timeframeTabs"
            :key="tab.value"
            type="button"
            class="border-b-2 px-1 pb-2.5 text-[14px] font-medium transition-colors"
            :class="
              activeTab === tab.value
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            "
            @click="setTab(tab.value)"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>

      <!-- Filters -->
      <div class="mb-6 flex items-center justify-between gap-4 py-2">
        <div class="flex flex-wrap items-center gap-3">
          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/50"
              @click="toggleFilter('assignee')"
            >
              <span class="font-normal text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.ASSIGNEE_LABEL') }}
              </span>
              {{ assigneeFilterLabel }}
              <span
                class="i-lucide-chevron-down size-3.5 text-muted-foreground opacity-50"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'assignee'"
              class="absolute left-0 top-full z-50 mt-1 max-h-64 w-[220px] overflow-y-auto rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in assigneeFilterOptions"
                :key="option.value"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': assigneeFilter === option.value }"
                @click="selectAssignee(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/50"
              @click="toggleFilter('status')"
            >
              <span class="font-normal text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.STATUS_LABEL') }}
              </span>
              {{ statusFilterLabel }}
              <span
                class="i-lucide-chevron-down size-3.5 text-muted-foreground opacity-50"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'status'"
              class="absolute left-0 top-full z-50 mt-1 w-[200px] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in statusFilterOptions"
                :key="option.value"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': statusFilter === option.value }"
                @click="selectStatus(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="relative">
            <RelayButton
              variant="outline"
              class="h-9 gap-2 rounded-lg border-border bg-background px-3 text-[13px] font-medium text-foreground shadow-sm hover:bg-muted/50"
              @click="toggleFilter('dueDate')"
            >
              <span class="font-normal text-muted-foreground">
                {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FILTER.DUE_LABEL') }}
              </span>
              {{ dueDateFilterLabel }}
              <span
                class="i-lucide-chevron-down size-3.5 text-muted-foreground opacity-50"
              />
            </RelayButton>
            <div
              v-if="openFilter === 'dueDate'"
              class="absolute left-0 top-full z-50 mt-1 w-[200px] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
            >
              <button
                v-for="option in dueDateFilterOptions"
                :key="option.value"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                :class="{ 'bg-muted': dueDateFilter === option.value }"
                @click="selectDueDate(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="ml-2 flex items-center gap-1">
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md text-muted-foreground hover:text-foreground"
            >
              <span class="i-lucide-list-filter size-4" />
            </RelayButton>
            <RelayButton
              variant="ghost"
              size="icon"
              class="size-8 rounded-md text-muted-foreground hover:text-foreground"
            >
              <span class="i-lucide-arrow-up-down size-4" />
            </RelayButton>
          </div>
        </div>

        <div class="relative w-64 shrink-0">
          <span
            class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
          />
          <RelayInput
            v-model="searchQuery"
            type="search"
            :placeholder="t('CONTACTS_LAYOUT.TASKS_VIEW.SEARCH_PLACEHOLDER')"
            class-name="h-9 rounded-lg border-border/80 bg-muted/20 pl-9 text-[13px] shadow-sm"
          />
        </div>
      </div>

      <!-- Content -->
      <div v-if="isFetching" class="flex h-[350px] items-center justify-center">
        <Spinner />
      </div>

      <div v-else-if="displayedTasks.length" class="flex flex-col gap-3">
        <div
          v-for="task in displayedTasks"
          :key="task.id"
          class="flex items-start gap-4 rounded-xl border border-border/60 bg-card p-4 shadow-sm transition-shadow hover:shadow-md"
        >
          <RelayCheckbox
            :model-value="!!task.completed"
            class="mt-1 border-muted-foreground/30"
            @update:model-value="value => setTaskCompleted(task, value)"
          />
          <div class="flex flex-1 flex-col gap-1.5">
            <div class="flex items-start justify-between gap-4">
              <div>
                <h3
                  class="text-[15px] font-semibold tracking-tight text-foreground"
                  :class="{
                    'line-through text-muted-foreground': task.completed,
                  }"
                >
                  {{ task.title }}
                </h3>
                <p
                  v-if="task.description"
                  class="mt-1 line-clamp-2 text-[13.5px] text-muted-foreground"
                >
                  {{ task.description }}
                </p>
              </div>
              <div class="flex items-center gap-2">
                <RelayBadge
                  variant="outline"
                  class="bg-muted/30 text-xs font-medium"
                >
                  {{ statusLabelFor(task) }}
                </RelayBadge>
                <div class="relative">
                  <RelayButton
                    variant="ghost"
                    size="icon"
                    class="size-7 text-muted-foreground hover:text-foreground"
                    @click="toggleTaskMenu(task.id)"
                  >
                    <span class="i-lucide-more-horizontal size-4" />
                  </RelayButton>
                  <div
                    v-if="openTaskMenu === task.id"
                    class="absolute right-0 top-full z-50 mt-1 w-[160px] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md"
                  >
                    <button
                      type="button"
                      class="flex w-full cursor-pointer items-center gap-2 rounded-sm px-3 py-2 text-left text-[13px] text-foreground hover:bg-muted"
                      @click="openEditTaskDialog(task)"
                    >
                      <span class="i-lucide-pencil size-3.5" />
                      {{ t('CONTACTS_LAYOUT.TASKS_VIEW.EDIT_TASK') }}
                    </button>
                    <button
                      type="button"
                      class="flex w-full cursor-pointer items-center gap-2 rounded-sm px-3 py-2 text-left text-[13px] text-destructive hover:bg-destructive/10"
                      @click="handleDeleteTask(task.id)"
                    >
                      <span class="i-lucide-trash size-3.5" />
                      {{ t('CONTACTS_LAYOUT.TASKS_VIEW.DELETE_TASK') }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-2 flex flex-wrap items-center gap-4">
              <div
                v-if="task.due_at"
                class="flex items-center gap-1.5 rounded-md px-2 py-0.5 text-[12px] font-medium"
                :class="
                  isOverdue(task)
                    ? 'bg-destructive/10 text-destructive'
                    : 'bg-muted/40 text-muted-foreground'
                "
              >
                <span class="i-lucide-calendar size-3.5" />
                {{ formatDate(task.due_at) }}
              </div>
              <div
                v-if="task.assignee_id"
                class="flex items-center gap-1.5 text-[12px] font-medium text-muted-foreground"
              >
                <span class="i-lucide-user size-3.5" />
                {{ getAgentName(task.assignee_id) }}
              </div>
              <div
                v-if="task.contacts?.length"
                class="flex items-center gap-1.5 text-[12px] font-medium text-muted-foreground"
              >
                <span class="i-lucide-link-2 size-3.5" />
                {{ task.contacts[0].name }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        v-else
        class="relative flex h-[350px] flex-col items-center justify-center rounded-xl border border-border/60 bg-card shadow-sm"
      >
        <h3 class="mb-1 text-[20px] font-semibold text-foreground">
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.NO_TASKS') }}
        </h3>
        <p class="text-[14px] font-medium text-muted-foreground">
          {{ t('CONTACTS_LAYOUT.TASKS_VIEW.NO_TASKS_SUBTITLE') }}
        </p>
      </div>
    </div>

    <Dialog
      ref="taskDialogRef"
      :title="
        editingTask
          ? t('CONTACTS_LAYOUT.TASKS_VIEW.EDIT_TASK')
          : t('CONTACTS_LAYOUT.TASKS_VIEW.ADD_TASK')
      "
      width="md"
      @confirm="handleSaveTask"
    >
      <div class="space-y-5 pt-2">
        <div class="flex flex-col gap-1.5">
          <RelayLabel>
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_TITLE') }}
          </RelayLabel>
          <RelayInput
            v-model="taskForm.title"
            :placeholder="
              t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_TITLE_PLACEHOLDER')
            "
            class-name="h-10 rounded-md border-border/80 text-[14px] shadow-sm"
          />
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel>
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DESCRIPTION') }}
          </RelayLabel>
          <textarea
            v-model="taskForm.description"
            :placeholder="
              t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DESCRIPTION_PLACEHOLDER')
            "
            class="min-h-[100px] w-full resize-y rounded-md border border-border/80 bg-background p-3 text-[14px] text-foreground shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="relative flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_ASSIGNEE') }}
            </RelayLabel>
            <RelayButton
              variant="outline"
              class="h-10 w-full justify-between rounded-md border-border/80 bg-background px-3 text-[14px] font-normal shadow-sm hover:bg-muted/50"
              @click="toggleFilter('formAssignee')"
            >
              <span class="truncate">
                {{ getAgentOptionLabel(taskForm.assigneeId) }}
              </span>
              <span class="i-lucide-chevron-down size-4 opacity-50" />
            </RelayButton>
            <div
              v-if="openFilter === 'formAssignee'"
              class="absolute left-0 right-0 top-full z-50 mt-1 max-h-48 overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
            >
              <button
                v-for="option in agentOptions"
                :key="`assignee-${option.value || 'none'}`"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] hover:bg-muted"
                @click="
                  taskForm.assigneeId = option.value;
                  closeMenus();
                "
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div class="relative flex flex-col gap-1.5">
            <RelayLabel>
              {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_CONTACT') }}
            </RelayLabel>
            <RelayButton
              variant="outline"
              class="h-10 w-full justify-between rounded-md border-border/80 bg-background px-3 text-[14px] font-normal shadow-sm hover:bg-muted/50"
              :class="
                !taskForm.contactId
                  ? 'text-muted-foreground'
                  : 'text-foreground'
              "
              @click="toggleFilter('formContact')"
            >
              <span class="truncate">
                {{ getContactOptionLabel(taskForm.contactId) }}
              </span>
              <span class="i-lucide-chevron-down size-4 opacity-50" />
            </RelayButton>
            <div
              v-if="openFilter === 'formContact'"
              class="absolute left-0 right-0 top-full z-50 mt-1 max-h-48 overflow-y-auto rounded-md border border-border bg-popover p-1 shadow-md"
            >
              <button
                v-for="option in contactOptions"
                :key="`contact-${option.value || 'none'}`"
                type="button"
                class="flex w-full cursor-pointer items-center rounded-sm px-3 py-2 text-left text-[13px] hover:bg-muted"
                @click="
                  taskForm.contactId = option.value;
                  closeMenus();
                "
              >
                {{ option.label }}
              </button>
            </div>
          </div>
        </div>

        <div class="flex flex-col gap-1.5">
          <RelayLabel>
            {{ t('CONTACTS_LAYOUT.TASKS_VIEW.FORM_DUE_DATE') }}
          </RelayLabel>
          <input
            v-model="taskForm.dueDate"
            type="datetime-local"
            class="h-10 w-full rounded-md border border-border/80 bg-background px-3 text-[14px] text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary/30"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>
