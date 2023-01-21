<script lang="ts">
	import { Canvas, InteractiveObject, OrbitControls, T, useLoader } from '@threlte/core';
	import { GLTF } from '@threlte/extras';
	import { spring } from 'svelte/motion';
	import { degToRad } from 'three/src/math/MathUtils';

	const scale = spring(1);
</script>

<div class="h-screen">
	<Canvas>
		<T.PerspectiveCamera makeDefault position={[3, 10, 10]} fov={24}>
			<OrbitControls maxPolarAngle={degToRad(80)} enableZoom={false} target={{ y: 0.5 }} />
		</T.PerspectiveCamera>

		<T.DirectionalLight castShadow position={[3, 25, 25]} />
		<T.DirectionalLight position={[-3, 10, -10]} intensity={0.4} />
		<T.AmbientLight intensity={0.2} />

		<GLTF
			url="/logo-3d.gltf"
			scale={{ x: 24, y: 24, z: 24 }}
			castShadow
			interactive
			on:click={() => {
				console.log('User clicked!');
			}}
		/>

		<!-- Floor -->
		<T.Mesh receiveShadow rotation.x={degToRad(-90)}>
			<T.CircleGeometry args={[3, 72]} />
			<T.MeshStandardMaterial color="white" />
		</T.Mesh>
	</Canvas>
</div>
