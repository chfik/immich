<script lang="ts">
  import UserPageLayout from '$lib/components/layouts/user-page-layout.svelte';
  import { Icon } from '@immich/ui';
  import { AssetMediaSize, deleteAssets } from '@immich/sdk';
  import { mdiCheckCircleOutline, mdiDelete } from '@mdi/js';
  import { useSwipe } from 'svelte-gestures';
  import { t } from 'svelte-i18n';
  import { getAssetThumbnailUrl } from '$lib/utils/asset-utils';
  import { handleError } from '$lib/utils/handle-error';
  import type { PageData } from './$types';

  interface Props {
    data: PageData;
  }

  let { data }: Props = $props();

  let queue = $state([...data.assets]);
  let isProcessing = $state(false);
  const totalCount = queue.length;

  const current = $derived(queue[0]);
  const progressText = $derived(
    current ? $t('review_swipe_progress', { values: { current: totalCount - queue.length + 1, total: totalCount } }) : '',
  );

  const previewUrl = $derived(
    current ? getAssetThumbnailUrl({ id: current.id, size: AssetMediaSize.Preview, cacheKey: current.thumbhash }) : '',
  );

  const clearCurrent = () => {
    queue = queue.slice(1);
  };

  const keepAsset = () => {
    clearCurrent();
  };

  const trashAsset = async () => {
    if (!current) {
      return;
    }

    isProcessing = true;
    try {
      await deleteAssets({ assetBulkDeleteDto: { ids: [current.id] } });
      clearCurrent();
    } catch (error) {
      handleError(error, $t('errors.unable_to_delete_assets'));
    } finally {
      isProcessing = false;
    }
  };

  const handleSwipe = (event: CustomEvent<{ direction: string }>) => {
    if (!event.detail?.direction || !current) {
      return;
    }

    if (event.detail.direction === 'right') {
      keepAsset();
    }

    if (event.detail.direction === 'left') {
      trashAsset();
    }
  };

  const { swipe, onswipe } = useSwipe(handleSwipe, { threshold: 40 });
</script>

<UserPageLayout title={data.meta.title}>
  <div class="max-w-5xl mx-auto flex flex-col gap-6">
    <div class="rounded-3xl border border-gray-200 dark:border-immich-dark-gray p-6 bg-white dark:bg-immich-dark-gray/70">
      <h1 class="text-2xl font-semibold text-gray-900 dark:text-white">{$t('review_swipe_title')}</h1>
      <p class="text-gray-600 dark:text-immich-dark-fg flex items-center gap-2 mt-2">
        <Icon icon={mdiCheckCircleOutline} size="18" class="text-immich-primary" />
        {$t('review_swipe_description')}
      </p>
    </div>

    {#if current}
      <div
        class="rounded-3xl overflow-hidden border border-gray-200 dark:border-immich-dark-gray bg-gray-50 dark:bg-immich-dark-bg"
      >
        <div class="relative aspect-[4/3] sm:aspect-video bg-black" use:swipe on:swipe={onswipe}>
          <img src={previewUrl} alt={current.originalFileName} class="w-full h-full object-contain" loading="lazy" />

          <div class="absolute inset-x-0 bottom-0 flex justify-between p-4 text-white text-sm pointer-events-none">
            <span class="bg-green-600/80 px-3 py-1 rounded-full">{$t('review_swipe_keep')}</span>
            <span class="bg-red-600/80 px-3 py-1 rounded-full">{$t('review_swipe_delete')}</span>
          </div>
        </div>

        <div class="flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div class="text-gray-700 dark:text-immich-dark-fg text-sm">{progressText}</div>

          <div class="flex gap-3">
            <button
              class="flex items-center gap-2 px-4 py-2 border border-gray-300 dark:border-immich-dark-gray rounded-xl hover:bg-gray-100 dark:hover:bg-immich-dark-gray disabled:opacity-50"
              on:click={keepAsset}
              disabled={isProcessing}
              data-testid="quick-review-keep"
            >
              <Icon icon={mdiCheckCircleOutline} size="18" />
              {$t('review_swipe_keep')}
            </button>

            <button
              class="flex items-center gap-2 px-4 py-2 rounded-xl bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
              on:click={trashAsset}
              disabled={isProcessing}
              data-testid="quick-review-trash"
            >
              <Icon icon={mdiDelete} size="18" />
              {$t('review_swipe_delete')}
            </button>
          </div>
        </div>
      </div>
    {:else}
      <div class="rounded-3xl border border-dashed border-gray-300 dark:border-immich-dark-gray p-8 text-center">
        <p class="text-lg text-gray-600 dark:text-immich-dark-fg">{$t('review_swipe_empty')}</p>
      </div>
    {/if}
  </div>
</UserPageLayout>
