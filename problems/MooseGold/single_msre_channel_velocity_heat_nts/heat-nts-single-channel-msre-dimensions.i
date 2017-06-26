# This input file tests outflow boundary conditions for the incompressible NS equations.
width = 3.048
height = 1.016
length = 162.56
nt_scale=1e13

[GlobalParams]
  num_groups = 2
  num_precursor_groups = 6
  use_exp_form = false
  group_fluxes = 'group1 group2'
  sss2_input = false
  account_delayed = false
  temperature = temp
  pre_concs = 'pre1 pre2 pre3 pre4 pre5 pre6'
  gamma = .0144 # Cammi .0144
  nt_scale = ${nt_scale}
[]

[Mesh]
  file = single_channel_msre_dimensions.msh
[]


[Variables]
  [./group1]
    order = FIRST
    family = LAGRANGE
    initial_condition = 1
    # scaling = 1e4
  [../]
  [./group2]
    order = FIRST
    family = LAGRANGE
    initial_condition = 1
    # scaling = 1e4
  [../]
  [./temp]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[AuxVariables]
  [./vel_x]
    block = 'fuel'
  [../]
  [./vel_y]
    block = 'fuel'
  [../]
  [./vel_z]
    block = 'fuel'
  [../]
  [./p]
    block = 'fuel'
  [../]
  [./power_density]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

# [PrecursorKernel]
#   var_name_base = pre
#   block = 'fuel'
#   outlet_boundaries = 'fuel_top'
#   u_func = vel_x_func
#   v_func = vel_y_func
#   w_func = vel_z_func
#   constant_velocity_values = false
#   nt_exp_form = false
#   family = MONOMIAL
#   order = CONSTANT
#   # jac_test = true
# []

[Kernels]
  # Neutronics
  [./diff_group1]
    type = GroupDiffusion
    variable = group1
    group_number = 1
  [../]
  [./sigma_r_group1]
    type = SigmaR
    variable = group1
    group_number = 1
  [../]
  [./fission_source_group1]
    type = CoupledFissionKernel
    variable = group1
    group_number = 1
  [../]
  # [./delayed_group1]
  #   type = DelayedNeutronSource
  #   variable = group1
  # [../]
  [./inscatter_group1]
    type = InScatter
    variable = group1
    group_number = 1
  [../]
  [./diff_group2]
    type = GroupDiffusion
    variable = group2
    group_number = 2
  [../]
  [./sigma_r_group2]
    type = SigmaR
    variable = group2
    group_number = 2
  [../]
  [./fission_source_group2]
    type = CoupledFissionKernel
    variable = group2
    group_number = 2
  [../]
  [./inscatter_group2]
    type = InScatter
    variable = group2
    group_number = 2
  [../]

[./temp_fuel_transport]
    type = INSTemperature
    u = vel_x
    v = vel_y
    w = vel_z
    variable = temp
    block = 'fuel'
  [../]
  [./temp_mod_transport]
    type = MatDiffusion
    D_name = 'k'
    variable = temp
    block = 'moderator'
  [../]
  [./temp_source_fuel]
    type = TransientFissionHeatSource
    variable = temp
    block = 'fuel'
  [../]
  [./temp_source_mod]
    type = GammaHeatSource
    variable = temp
    block = 'moderator'
    average_fission_heat = 'average_fission_heat'
  [../]
[]

[AuxKernels]
  [./fuel]
    block = 'fuel'
    type = FissionHeatSourceTransientAux
    variable = power_density
  [../]
  [./moderator]
    block = 'moderator'
    type = ModeratorHeatSourceTransientAux
    average_fission_heat = 'average_fission_heat'
    variable = power_density
  [../]
[]

[BCs]
  [./temp_inlet]
    boundary = 'fuel_bottom'
    variable = temp
    value = 900
    type = DirichletBC
  [../]
[]

[Materials]
  [./fuel]
    type = GenericMoltresMaterial
    property_tables_root = '../property_file_dir/newt_msre_fuel_'
    interp_type = 'monotone_cubic'
    block = 'fuel'
    prop_names = 'k cp rho'
    prop_values = '.0553 1967 2.146e-3' # Robertson MSRE technical report @ 922 K
    peak_power_density = peak_power_density
    controller_gain = 1e-4
  [../]
  [./moder]
    type = GenericMoltresMaterial
    property_tables_root = '../property_file_dir/newt_msre_mod_'
    interp_type = 'monotone_cubic'
    prop_names = 'k cp rho'
    prop_values = '.312 1760 1.86e-3' # Cammi 2011 at 908 K
    block = 'moderator'
    peak_power_density = peak_power_density
    controller_gain = 0
  [../]
[]

[Debug]
  show_var_residual_norms = true
[]

[Preconditioning]
  [./SMP_PJFNK]
    type = SMP
    full = true
    solve_type = PJFNK
    ksp_norm = none
  [../]
[]

[Executioner]
  # type = Steady
  type = Transient
  dt = 1
  num_steps = 1
  # dt = 5e-5
  # num_steps = 5
  # petsc_options_iname = '-ksp_gmres_restart -pc_type -sub_pc_type -sub_pc_factor_levels'
  # petsc_options_value = '300                bjacobi  ilu          4'
  # petsc_options_iname = '-pc_type -sub_pc_type'
  # petsc_options_value = 'asm	  lu'
  petsc_options_iname = '-pc_type -pc_factor_shift_type -pc_factor_shift_amount -ksp_type -snes_linesearch_minlambda'
  petsc_options_value = 'lu NONZERO 1.e-10 preonly 1e-3'
  petsc_options = '-snes_converged_reason -ksp_converged_reason -snes_linesearch_monitor'
  # line_search = none
  nl_rel_tol = 1e-8
  nl_max_its = 50
  l_max_its = 300
[]

[Outputs]
  print_perf_log = true
  exodus = true
  csv = true
  file_base = 'out'
[]

[Functions]
  [./fuel_source_function]
    type = ParsedFunction
    value = '10 * sin(pi * z / ${length})'
  [../]
  [./mod_source_function]
    type = ParsedFunction
    value = '.0144 * 4'
  [../]
  [./temp_ic]
    type = ParsedFunction
    value = '900 + 100 / ${length} * z'
  [../]
[]

[ICs]
  [./fuel]
    type = FunctionIC
    variable = temp
    function = temp_ic
  [../]
[]

[MultiApps]
  [./sub]
    type = TransientMultiApp
    app_type = MoltresApp
    positions = '0 0 0'
    input_files = solution_aux_exodus.i
  [../]
[]

[Transfers]
  [./vel_x]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = sub
    source_variable = vel_x
    variable = vel_x
  [../]
  [./vel_y]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = sub
    source_variable = vel_y
    variable = vel_y
  [../]
  [./vel_z]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = sub
    source_variable = vel_z
    variable = vel_z
  [../]
  [./p]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = sub
    source_variable = p
    variable = p
  [../]
[]

[Postprocessors]
  [./average_fission_heat]
    type = AverageFissionHeat
    execute_on = 'linear nonlinear'
    outputs = 'console'
    block = 'fuel'
  [../]
  [./peak_power_density]
    type = ElementExtremeValue
    value_type = max
    variable = power_density
    execute_on = 'linear nonlinear timestep_begin'
  [../]
[]
