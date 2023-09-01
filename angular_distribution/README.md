# angular_distribution
This folder contains the codes needed for angular distribution analysis of the target neurons in our dataset, which was required for our research[^1].

We consider the intercellular space of the cerebellar molecular layer to be composed of Purkinje cell dendrites and their surrounding spaces. We analyzed how much volume the neurons of each type occupy the surrounding space of dendritic shafts of Purkinje cells in each direction. Surrounding space of the PC dendritic shaft is the $2\mu m$-thick tube, which is obtained by subtracting the shaft component of a Purkinje-cell from the its dilation by the sphere of $2\mu m$ radius. Each voxel in the surrounding space is matched to the nearest point on the skeleton of PC dendritic shaft, and the direction of the voxel relative to the matched skeletal point is quantified in terms of angles measured from the directional basis locally defined on the skeletal point.

Thus, we should prepare shaft-spine separated segments for PCs before we proceed (see the [`shaft-spine separation`](https://github.com/cns-kim-lab/park_cerebellar_disinhibition/skeletonization#shaft-spine-separation) section in `skeletonization`). In addition to that, we also need skeletons for the dendritic shafts (see [`shaft skeletonization`](https://github.com/cns-kim-lab/park_cerebellar_disinhibition/skeletonization#shaft-skeletonization) in `skeletonization`).

## Derivation of locally defined directional basis on PC shaft skeletons
relevant codes: `get_directions_on_pc_shaft.m`

After removing spines from dendritic shaft and extracting the skeleton from the shaft component, we assign local directional basis vectors to each point on the shaft skeleton.

## Angular distribution analysis
- **Check**: Compare with the version modified and used by `cjpark`.

### Matching the voxels in surrounding space to shaft skeleton points
relevant codes: `iteration_match_volume_to_shaft_skeleton.m`, `match_volume_to_shaft_skeleton_contain_volume_from_pc_w_sphere.m`

Shaft components are dilated to obtain the tube of surrounding space. 
Voxels in the tube are matched to a point on the shaft skeleton in the manner explained as following:
1. Identify the nearest surface voxel of Purkinje cell dendrite (shaft, spine combined) from each voxel in surrounding space.
2. If the nearest surface voxel belongs to the *shaft* part, we find a match for the voxel by extracting TEASAR route from the surface voxel to the root of the shaft skeleton. Those TEASAR routes converge fast, almost in straight lines, to the shaft skeleton. We take the point of convergence as the match for the voxel in surrounding space.
3. If the nearest surface voxel belongs to the *spine* part, we refer to the 'root' point of the spine, or the midpoint at the interface to the shaft. Then we trace the TEASAR route from the spine root point to the root of the shaft skeleton. The TEASAR route converges fast to the shaft skeleton, and we take the point of convergence as the match for the voxel in surrounding space.

In the procedure, the type of each surrounding space voxel is identified as one among PC, CF, IN, PF, etc., or void, and it is recorded for later use.

### Derivation of directions
relevant codes: `directional_analysis_of_surrounding_volume_of_pc_dend.m`

We derive the direction of each voxel in terms of angles relative to the local directional basis (defined in `## Derivation of locally defined directional basis on PC shaft skeletons`). Displacement vectors of the voxel in surrounding space from its match point on the shaft skeleton (found by `### Matching the voxels in surrounding space to shaft skeleton points`) are first projected to the plane perpendicular to the local tangential vector of the dendritic skeleton, and its angles with the 'horizontal' and 'vertical' vectors are measured.

### Angular analysis
relevant codes: `draw_polar_plots_for_angular_dist_of_surroundings.m`

We take angular bins around the shaft skeleton, and count the number or proportions of the voxels of each type in each angular bin. The result is represented in polarplot style.

[^1]: reference of the paper

