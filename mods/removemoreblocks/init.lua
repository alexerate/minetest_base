--minetest.register_alias("moreblocks:stair_sandstonebrick", "stairs:stair_sandstonebrick")

removemoreblocksnodes = {
	"slab_acacia_wood", "slab_aspen_wood", "slab_brick", "slab_bronzeblock", "slab_cobble", "slab_copperblock", "slab_desert_cobble", "slab_desert_sandstone",
	"slab_desert_sandstone_block", "slab_desert_sandstone_brick", "slab_desert_stone", "slab_desert_stone_block", "slab_desert_stonebrick", "slab_goldblock", "slab_junglewood",
	"slab_mossycobble", "slab_obsidian", "slab_obsidian_block", "slab_obsidianbrick", "slab_pine_wood", "slab_sandstone", "slab_sandstone_block", "slab_sandstonebrick",
	"slab_silver_sandstone", "slab_silver_sandstone_block", "slab_silver_sandstone_brick", "slab_steelblock", "slab_stone", "slab_stone_block", "slab_stonebrick",
	"slab_straw", "slab_wood",
	"stair_acacia_wood", "stair_aspen_wood", "stair_brick", "stair_bronzeblock", "stair_cobble", "stair_copperblock",
	"stair_desert_cobble", "stair_desert_sandstone", "stair_desert_sandstone_block", "stair_desert_sandstone_brick", "stair_desert_stone", "stair_desert_stone_block", "stair_desert_stonebrick", "stair_goldblock",
	"stair_junglewood", "stair_mossycobble", "stair_obsidian", "stair_obsidian_block", "stair_obsidianbrick", "stair_pine_wood", "stair_sandstone",
	"stair_sandstone_block", "stair_sandstonebrick", "stair_silver_sandstone", "stair_silver_sandstone_block", "stair_silver_sandstone_brick", "stair_steelblock", "stair_stone",
	"stair_stone_block", "stair_stonebrick", "stair_straw", "stair_wood",
}

for i, name in ipairs(removemoreblocksnodes) do
	minetest.register_alias("moreblocks:"..name,"stairs:"..name)
end
