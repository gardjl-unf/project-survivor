Game = Game or {
  elapsed = 0.0,
  boot_sfx_played = false,
}

function update(dt)
  Game.elapsed = Game.elapsed + dt
  if not Game.boot_sfx_played and Game.elapsed > 0.25 then
    Crown.log("boot -> running")
    Crown.set_state("running")
    Audio.set_master_gain(0.8)
    Audio.play_event("file:assets/audio/DavidKBD - Pink Bloom Pack - 08 - Lost Spaceship's Signal.wav")
    Game.boot_sfx_played = true
  end
end

function Crown.npc_decide_goal(query)
  if query == nil then
    return nil
  end
  if query.in_combat then
    return nil
  end
  if query.hostile then
    if query.distance_to_player <= 6 then
      return 3 -- PATROL
    end
    return 1 -- WANDER
  end
  return query.current_goal
end
