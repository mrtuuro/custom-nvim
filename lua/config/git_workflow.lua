return {
  remote = "origin",
  base_branch = "master",
  restore_branch_after_propagate = true,

  -- target_branch = source_branch
  dependencies = {
    -- feature-2 = "feature-1",
    B = "A",
  },
}
