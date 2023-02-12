<script>
	const sites = [
		{
			name: 'projects',
			content: 'code forge',
			link: 'https://github.com/kalebpace'
		},
		{
			name: 'book',
			content: 'schedule a call',
			link: 'https://cal.com/kalebpace'
		},
		{
			name: 'blog',
			content: 'read about projects',
			link: '/blog'
		},
		// {
		// 	name: 'know',
		// 	content: 'knowledge garden',
		// 	link: 'https://know.kalebpace.me'
		// }
		// {
		// 	name: 'graph.me'.split('.'),
		// 	content: 'view analytics',
		// 	link: 'https://graph.kalebpace.me'
		// },
		// {
		// 	name: 'pay.me'.split('.'),
		// 	content: 'support my work',
		// 	link: 'https://pay.kalebpace.me'
		// }
	];
</script>

<main class="transition-all grid grid-cols-1 sm:grid-cols-2 gap-8 place-content-center mx-auto">
	{#each sites as site}
		<a href={site.link}>
			<div class="dark:text-white px-6 py-2">
				<h5 class="text-2xl pb-4">
					{site.name}
				</h5>
				<p class="text-xs uppercase">{site.content}</p>
			</div>
		</a>
	{/each}
</main>
