# デバッグコマンド一覧
- デモリッシャー一覧
'''
 /c local s=game.player.surface; local t=0; local d={}; for _,e in pairs(s.find_entities_filtered{force="enemy"}) do if e.name:find("demolisher") and not e.name:find("segment") and not e.name:find("trail") and not e.name:find("tail") then t=t+1; d[e.name]=(d[e.name]or 0)+1 end end; game.print("Total: "..t); for n,c in pairs(d) do game.print(n..": "..c) end
 '''
- 研究レベル増加
'''
/c game.player.force.technologies["manis-demolisher-cap-down"].level = 21
'''
