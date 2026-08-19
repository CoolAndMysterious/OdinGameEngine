package ECS

import ecs "../../Shared/odecs/src"


World :: ecs.World
EntityID :: ecs.EntityID
Observer_Def :: ecs.Observer_Def
ObserverID   :: ecs.ObserverID


// creation Boii
Create_World :: proc()-> ^World{
    return ecs.create_world()
}

Destroy_World :: proc(world: ^World) {
	ecs.delete_world(world)
}


Flush :: proc(world: ^World) {
    ecs.flush(world)
}



// Entities.

Create_Entity :: proc(world: ^World, components: ..any) -> EntityID {
	return ecs.add_entity(world, ..components)
}

Destroy_Entity :: proc(world: ^World, entity: EntityID) {
	ecs.remove_entity(world, entity)
}

Entity_Alive :: proc(world: ^World, entity: EntityID) -> bool {
	return ecs.entity_alive(world, entity)
}


//// components


// Add a component value to an entity.
Add_Component :: proc(world: ^World, entity: EntityID, component: $T,) {
	ecs.add_component(world, entity,component)
}

// Attach a component to an entity type/archetype.
Add_Component_To_Type :: proc(world: ^World, $Type: typeid, component: $T) {
	ecs.add_component(world, Type, component)
}

// Attach a tag/trait to an entity type/archetype.
Add_Tag_To_Type :: proc(world: ^World, $Type: typeid, $Tag: typeid) {
	ecs.add_component(world, Type, Tag)
}

// Add multiple component values to one entity.
Add_Components :: proc(world: ^World, entity: EntityID, components: ..any ) {
	ecs.add_components(world, entity, ..components)
}

// Remove a component from an entity.
Remove_Component :: proc(world: ^World, entity: EntityID, $T: typeid) {
	ecs.remove_component(world, entity, T)
}

// Get a mutable pointer to a component.
Get_Component :: proc(world: ^World, entity: EntityID, $T: typeid) -> ^T {
	return ecs.get_component(world, entity, T)
}

// Check whether an entity has a component.
Has_Component :: proc(world: ^World, entity: EntityID, $T: typeid) -> bool {
	return ecs.has_component(world, entity, T)
}



//// Relation Traits (attach to relation types)

// entity can have only one target per relation
Add_Exclusive :: proc(world: ^World, $Relation: typeid) {
	ecs.add_component(world, Relation, ecs.Exclusive)
}

// delete entity when its target is deleted
Add_Cascade :: proc(world: ^World, $Relation: typeid) {
	ecs.add_component(world, Relation, ecs.Cascade)
}




//// Queries - one-line iteration with automatic deferred cleanup

@(deferred_in=ecs.query_auto_cleanup)
Query :: proc(world: ^World, types: []typeid) -> ecs.Query {
	return ecs.query(world, types)
}


Get_Table :: proc(world: ^World, arch: ^ecs.Archetype, $T: typeid ) -> []T {
	return ecs.get_table(world, arch, T)
}


Get_Entities :: proc(arch: ^ecs.Archetype) -> []EntityID {
	return ecs.get_entities(arch)
}


// ============================================================
// QUERY TERMS
// ============================================================

// Require ALL terms.
And :: proc(types: ..typeid) -> typeid {
	return ecs.and(..types)
}

// Alias for And.
All :: proc(types: ..typeid) -> typeid {
	return ecs.all(..types)
}

// Require SOME of the terms.
Or :: proc(types: ..typeid) -> typeid {
	return ecs.or(..types)
}

// Alias for Or.
Some :: proc(types: ..typeid) -> typeid {
	return ecs.some(..types)
}

// Require NONE of the terms.
Not :: proc(types: ..typeid) -> typeid {
	return ecs.not(..types)
}

// Alias for Not.
None :: proc(types: ..typeid) -> typeid {
	return ecs.none(..types)
}

// Hierarchy/depth-ordered iteration.
Hierarchy :: proc($R: typeid) -> typeid {
	return ecs.hierarchy(R)
}

// Relation + target pair.
/*Pair :: proc($Relation: typeid, $Target: typeid) -> typeid {
	return ecs.pair(Relation, Target)
}*/



/////////// the pair group ?


Pair :: proc {
	Pair_Type_Type,
	Pair_Type_Entity,
	Pair_Entity_Type,
	Pair_Entity_Entity,
}


Pair_Type_Type :: proc(
	$Relation: typeid,
	$Target: typeid,
) -> typeid {
	return ecs.pair(Relation, Target)
}


Pair_Type_Entity :: proc(
	$Relation: typeid,
	target: EntityID,
) -> typeid {
	return ecs.pair(Relation, target)
}


Pair_Entity_Type :: proc(
	relation: EntityID,
	$Target: typeid,
) -> typeid {
	return ecs.pair(relation, Target)
}


Pair_Entity_Entity :: proc(
	relation: EntityID,
	target: EntityID,
) -> typeid {
	return ecs.pair(relation, target)
}


// ============================================================
// PAIRS / More Pairsss T T 
// ============================================================

// Entity + relation type + target entity.
// Tag pair: (Relation, Target)
Add_Pair :: proc {
	Add_Pair_Tag,
	Add_Pair_Data,
}


// Add a tag pair.
// Example: Add_Pair(&world, child, ChildOf, parent)
Add_Pair_Tag :: proc(world: ^World, entity: EntityID, $R: typeid, target: EntityID) {
	ecs.add_pair(world, entity, R, target)
}


// Add a data pair.
// Example: Add_Pair(&world, chest, Contains{50}, gold)
Add_Pair_Data :: proc(world: ^World, entity: EntityID, data: $R, target: EntityID) {
	ecs.add_pair(world, entity, data, target)
}


// Check whether an entity has a specific relation/target pair.
Has_Pair :: proc(world: ^World, entity: EntityID, $R: typeid, $T: typeid) -> bool {
	return ecs.has_pair(world, entity, R, T)
}


// Get pair data.
//Returns a pointer to the relation's data.
Get_Pair :: proc(world: ^World, entity: EntityID, $R: typeid, $T: typeid) -> ^R {
	return ecs.get_pair(world, entity, R, T)
}



// ============================================================
// OBSERVERS
// ============================================================

Observe :: proc(world: ^World, def: Observer_Def, callback: proc(^World, EntityID)) -> ObserverID {
	return ecs.observe(world, def, callback)
}


Unobserve :: proc(world: ^World, id: ObserverID) {
	ecs.unobserve(world, id)
}


On_Add :: proc(types: ..typeid) -> Observer_Def {
	return ecs.on_add(..types)
}

On_Remove :: proc(types: ..typeid) -> Observer_Def {
	return ecs.on_remove(..types)
}