import Base.length
import Base.reshape
import AxisArrays.AxisArray
import JuMP.value
using AxisArrays
using JuMP

function emptySetException(sets, values, floatbool=false)
    try
        return parameter(sets, values)
    catch
        if floatbool
            return Float64[]
        else
            return Int64[]
        end
    end
end

##TODO Get rid of union types
struct Parameter
    # TODO: change AxisArray types back to heavily specified types like:
    #       AxisArray{Float64,1,Array{Float64,1},Tuple{Axis{:row,Array{String,1}}}} ?
    #       Problem is that many Array{Float64, 1} can be empty so PyCall makes them Array{Any, 1}
	 ###  Sets  ###
	 #Storage::Array{String,1}      # Set B in math; new; B = "Elec","HotThermal","ColdThermal"
     TechClass::Array{String,1}    # Set C
	 DemandBin::UnitRange{Int64}   # Set E
	 #FuelType::Array{String,1}     # Set F; new; F = {"NaturalGas"} for CHP and whatever fuel source is used for Boiler
     TimeStep::UnitRange{Int64}    # Set H
     TimeStepBat::UnitRange{Int64} # Set H union {0}
	 #Subdivision::Array{String,1}	# Set K; new; elements = { "CapCost", "FuelBurn" }
	 Month::UnitRange{Int64} 	    # Set M
	 DemandMonthsBin::UnitRange{Int64}	# Set N
	 Ratchets::UnitRange{Int64}	   # Set R
     Seg::UnitRange{Int64}	       # Set S
	 Tech::Array{String,1}         # Set T in math
	 FuelBin::UnitRange{Int64}	   # To be removed
	 PricingTier::UnitRange{Int64}  # Set U: Pricing Tiers (proposed revision) #new
	 NMILRegime::Array{String,1}	# Set V: Net-metering Regimes
	 
	 ###  Subsets and Indexed Sets  ####
	 #ElecStorage::Array{String,1}  # B^{e} \subset B: Electrical energy storage systems
	 #HotTES::Array{String,1}  # B^{h} \subset B: Hot thermal energy storage systems (IGNORE)
	 #ColdTES::Array{String,1}  # B^{c} \subset B: Cold thermal energy storage systems (IGNORE)
	 #ThermalStorage::Array{String,1}  # B^{th} \subset B: Thermal energy storage systems (IGNORE)
	 #FuelTypeByTech::AxisArray{Int64,2,Array{Int64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}}}}  # F_t: Fuel types accessible by technology t
	 TimeStepRatchetsMonth   #  H_m: Time steps in month m
	 TimeStepRatchets   #  H_r: Time steps in ratchet r
     TimeStepsWithGrid::Array{Int64,1}  # H_g: Time steps with grid connection
     TimeStepsWithoutGrid::Array{Int64,1}	 # H \setminus H_g: Time steps without grid connection 
	 #SubdivsionByTech K_t \subset K: Subdivisions applied to technology t
	 #CapCostSeg::UnitRange{Int64}  # K^c \subset K: Capital Cost Subdivisions
	 #FuelBurnSlopeSeg::UnitRange{Int64} # K^f \subset K: Fuel Burn Subdivisions   (IGNORE)
	 DemandLookbackMonths::Array{Any,1}   # M^{lb}: Look back months considered for peak pricing 
	 #SegByTechSubdivision::AxisArray{Int64,3,Array{Float64,3},Tuple{Axis{:row,Array{String,1}},Axis{:col,UnitRange{Int64}},Axis{:page,UnitRange{Int64}}}} # S_{kt}: System size segments from segmentation k applied to technology t
	 #TechsChargingStorage::AxisArray{Array{Int64,1},1,Array{Array{Int64,1},1},Tuple{Axis{:row,UnitRange{Int64}}}} # T_b \subset T: Technologies that can charge storage system b
	 #TechsInClass::AxisArray{Array{Int64,1},1,Array{Array{String,1},1},Tuple{Axis{:row,UnitRange{Int64}}}} # T_c \subset T: Technologies that are in class c
	 #TechsByFuelType::AxisArray{Array{Int64,1},1,Array{Array{String,1},1},Tuple{Axis{:row,UnitRange{Int64}}}}   # T_f \subset T: Technologies that burn fuel type f
	 #TechsByPricingTier::AxisArray{Int64,2,Array{Int64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}}}}  # T_u  \subset T: Technologies that access pricing tier u
	 #TechsByNMILRegime::AxisArray{Int64,2,Array{Int64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}}}} # T_v \subset T: Technologies that may acess net-meterng regime v 
	 #AbsorptionChillers::Array{String,1}  # T^{ac} \subset T: Absorption Chillers (IGNORE)
	 #CHPTechs::Array{String,1}  # T^{CHP} \subset T: CHP technologies (IGNORE)
	 #CoolingTechs::Array{String,1}  # T^{cl} \subset T: Cooling technologies (IGNORE)
	 #ElectricTechs::Array{String,1}  # T^{e} \subset T: Electricity-producing technologies
	 #ElectricChillers::Array{String,1}  # T^{ec} \subset T: Electric chillers  (IGNORE) 
	 #FuelBurningTechs::Array{String,1}  # T^{f} \subset T: Fuel-burning technologies
	 #HeatingTechs::Array{String,1}  # T^{ht} \subset T: Heating technologies (IGNORE)
	 #TechsNoTurndown::Array{String,1}  # T^{ac} \subset T: Technologies that cannot turn down, i.e., PV and wind
	 #TechsTurndown::Array{String,1}  # This is just T \setminus T^{ac}; not in the math
	 #PricingTiersByTech::AxisArray{Array{Int64,1},1,Array{Array{String,1},1},Tuple{Axis{:row,UnitRange{Int64}}}}   # U_t \subset U:  Pricing tiers accessible by technology td
	 #PricingTiersNM::Array{Int64}  # U^{nm} \subset U: Pricing Tiers Used in net-metering
	 
	 ###  Parameters and Tables supporting Indexed Sets ###
	 TechToNMILMapping#::AxisArray{Int64,2,Array{Int64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}}}}  # Defines set T_v: Technologies that may be access net-metering regime v 
	 
	 ###  Scaling Parameters ###
	 TimeStepScaling::Float64  # \Delta: Time step scaling [h]
	 
	 ###  Parameters for Costs and their Functional Forms ###
     AnnualMinCharge::Float64    # c^{amc}: Utility annual minimum charge
     MonthlyMinCharge::Float64    # c^{mmc}: Utility monthly minimum charge  (not in math; will use this in min charge calculation)
	 FixedMonthlyCharge::Float64  # c^{fmc}: Utility monthly fixed charge
	 StorageCostPerKW::Float64    # c^{kW}_{b}:  Capital cost per unit power capacity of storage system b [$/kW]    NOTE: Needs to be updated for set B
     StorageCostPerKWH::Float64   # c^{kWh}_{b}:  Capital cost per unit energy capacity of storage system b [$/kWh]  NOTE: Needs to be updated for set B 
	 #StoragePowerCost::AxisArray{Float64,1,Array{Float64,1},Axis{:row,Array{String,1}}}  # c^{kW}_{b}:  Capital cost per unit power capacity of storage system b [$/kW]  (NEW)
	 #StorageEnergyCost::AxisArray{Float64,1,Array{Float64,1},Axis{:row,Array{String,1}}}  # c^{kWh}_{b}:  Capital cost per unit energy capacity of storage system b [$/kWh]  (NEW)
	 #FuelCost::AxisArray{Float64} # c^{u}_{f}: Unit cost of fuel type f [$/MMBTU]  in math  (NEW)
	 #ElecRate::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,UnitRange{Int64}}}}  #   c^{g}_{uh}: Grid energy cost in energy demand tier u during time step h  (NEW)
	 OMperUnitSize # c^{om}_{t}: Operation and maintenance cost of technology t per unit of system size [$/kW]
     OMcostPerUnitProd
     
	 ExportRates    # to be replaced by GridExportRates
	 #GridExportRates::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{Int64,1}}, Axis{:col,UnitRange{Int64}}}}    # c^{e}_{uh}: Export rate for energy in energy pricing tier u in time step h   (NEW)
	 CapCostSlope   # c^{cm}_{ts}: Slope of capital cost curve for technology t in segment s 
     CapCostYInt  # c^{cb}_{ts}: Y-Intercept of capital cost curve for technology t in segment s 
     CapCostX    # X-value of inflection point (will be changed)
	 #For the replacement of CapCostX, see new parameters SegmentLB and SegmentUB in section "System size and fuel limit parameters"
	 DemandRates  # c^{r}_{re}: Cost per unit peak demand in tier e during ratchet r
	 DemandRatesMonth   # c^{rm}_{mn}: Cost per unit peak demand in tier n during month m
	 
	 ###  Demand Parameters ###
	 LoadProfile   # Covers Electrical Load and Thermal Load Profiles; this is to be split into three parameters in the math
	 # ElecLoad::Array{Float64,1}  # \delta^{d}_{h}: Electrical load in time step h   [kW]
	 # HeatingLoad::Array{Float64,1}  # \delta^{bo}_{h}: Heating load in time step h   [MMBTU/hr]
	 # CoolingLoad::Array{Float64,1}  # \delta^{c}_{h}: Cooling load in time step h   [kW]
     DemandLookbackPercent::Float64    # \delta^{lp}: Demand Lookback proportion [fraction]
     MaxDemandInTier::Array{Float64,1}  # \delta^{t}_{e}: Maximum power demand in ratchet e
     MaxDemandMonthsInTier::Array{Float64,1}   # \delta^{mt}_{n}: Maximum monthly power demand in tier n
	 #MaxGridSales::Array{Float64,1}   # \delta^{gs}_{u}: Maximum allowable energy sales in tier u in math; equal to sum of LoadProfile["1R",ts] on set TimeStep for tier 1 (analogous "1W") and unlimited for "1X"
     MaxUsageInTier::Array{Float64,1}   # \delta^{tu}_{u}: Maximum monthly energy demand in tier u
	 
	 
	 ###  Incentive Parameters ###
	 NMILLimits   # i^{n}_{v}: Net metering and interconnect limits in net metering regime v [kW]
     
     MaxProdIncent           # \bar{i}_t: Upper incentive limit for technology t [$]
	 #ProductionIncentiveRate::AxisArray  # i^{r}_{t}: Incentive rate for technology t [$/kWh] (NEW)
	 MaxSizeForProdIncent    # \bar{i}^{\sigma}_t: Maximum system size to obtain production incentive for technology t [kW]	 
	 
	 ###  Technology-specific Time-series Factor Parameters ###
	 #ProductionFactor::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,UnitRange{Int64}}}}     #f^{p}_{th}  Production factor of technology t and time step h  [unitless]  (NEW)
     # f^{fa}_{th}: Fuel burn ambient correction factor of technology t at time step h [unitless] 
	 # f^{ha}_{th}: Hot water ambient correction factor of technology t at time step h [unitless] 
	 # f^{ht}_{th}: Hot water thermal grade correction factor t correction factor of technology t at time step h [unitless] 
	 # f^{ed}_{th}: Fuel burn ambient correction factor of technology t at time step h [unitless] 
	 
	 ###  Technology-specific Factor Parameters ###
	 TurbineDerate  # f^{d}_{t}: Derate factor for turbine technologyt [unitless]
     MinTurndown     # f^{td}_{t}:  Minimum turn down for technology t [unitless]
     pwf_prod_incent   # f^{pi}_t: Present worth factor for incentives for technology t [unitless] 
	 LevelizationFactor    # f^{l}_{t}: Levelization factor of technology t [unitless]
     LevelizationFactorProdIncent   # f^{pi}_{t}: Levelization factor of production incentive for technology t [unitless]
	 
	 ###  Generic Factor Parameters ###
	 pwf_om::Float64  # f^{om}: Operations and maintenance present worth factor [unitless] 
     pwf_e::Float64   # f^{e}: Energy present worth factor [unitless] 
	 r_tax_owner::Float64      # f^{tow}: Tax rate factor for owner [fraction]
     r_tax_offtaker::Float64   # f^{tot}: Tax rate factor for offtaker [fraction]
	 
	 ###  System Size and Fuel Limit Parameters ###
	 TechClassMinSize   #  \ubar{b}^{\sigma}_{c}: Minimum system size for technology class c [kW]
	 MaxSize    #  \bar{b}^{\sigma}_{t}: Maximum system size for technology t [kW]
	 #SegmentMinSize::AxisArray{Float64,3,Array{Float64,3},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}},Axis{:page,UnitRange{Int64}}}}  # \ubar{b}^{\sigma s}_{tks}: Minimum system size for technology t, subdivision k, segments
	 #SegmentMaxSize::AxisArray{Float64,3,Array{Float64,3},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}},Axis{:page,UnitRange{Int64}}}}  # \bar{b}^{\sigma s}_{tks}: Maximum system size for technology t, subdivision k, segments
	 #FuelLimit::AxisArray # b^{fa}_{f}: Amount of available fuel for type f [MMBTU]   (NEW)
	 
	 ###  Efficiency Parameters ###
	 #ChargeEfficiency::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}}}}  # \eta^{esi}_{bt}: Efficiency of charging storage system b using technology t  [fraction] (NEW)
	 #GridChargeEfficiency::Float64   # \eta^{esig}: Efficiency of charging electrical storage using grid power [fraction] (NEW)
     #DischargeEfficiency::AxisArray  # \eta^{eso}_{b}: Efficiency of discharging storage system b [fraction] (NEW)
	 # \eta^{bo}: Boiler efficiency [fraction]
	 # \eta^{ecop}: Electric chiller efficiency [fraction]
	 # \eta^{acop}: Absorption chiller efficiency [fraction]
	 
	 
	 ###  Storage Parameters ###
     MinStorageSizeKWH::Float64     # \bar{w}^{bkWh}_{b}: Maximum energy capacity of storage system b (needs to be indexed on b)
     MaxStorageSizeKWH::Float64     # \ubar{w}^{bkWh}_{b}: Minimum energy capacity of storage system b (needs to be indexed on b )
	 MinStorageSizeKW::Float64     # \bar{w}^{bkW}_{b}: Maximum power capacity of storage system b (needs to be indexed on b )
     MaxStorageSizeKW::Float64     # \ubar{w}^{bkW}_{b}: Minimum power capacity of storage system b (needs to be indexed on b )
     StorageMinChargePcent::Float64     #  \ubar{w}^{mcp}_{b}: Minimum state of charge of storage system b
     InitSOC::Float64    # w^{i}_{b} Initial percent state of charge for storage system b
     #StorageMinSizeEnergy::AxisArray     # \bar{w}^{bkWh}_{b}: Maximum energy capacity of storage system b [kWh]
     #StorageMaxSizeEnergy::AxisArray     # \ubar{w}^{bkWh}_{b}: Minimum energy capacity of storage system b [kWh]
     #StorageMinSizePower::AxisArray     # \bar{w}^{bkW}_{b}: Maximum power capacity of storage system b [kW]
     #StorageMaxSizePower::AxisArray     # \ubar{w}^{bkW}_{b}: Minimum power capacity of storage system b [kW]
     #StorageMinSOC::AxisArray     #  \ubar{w}^{mcp}_{b}: Minimum state of charge of storage system b [fraction]
     #StorageInitSOC::AxisArray  #Initial state of charge of storage system b [fraction]
	 
	 ###  Fuel Burn Parameters ###
	 #FuelBurnSlope::AxisArray # m^\text{fm}_{t}: Fuel burn rate slope parameter for technology t
	 #FuelBurnYInt::AxisArray # m^\text{fb}_{t}: Fuel burn rate slope parameter for technology t
	 
	 ###  CHP Thermal Performance Parameters ###
	 
	 
	 ### New parameters (commented copies above ###
	 #StoragePowerCost::AxisArray{Float64,1,Array{Float64,1},Axis{:row,Array{String,1}}}  # c^{kW}_{b}:  Capital cost per unit power capacity of storage system b [$/kW]  (NEW)
	 #StorageEnergyCost::AxisArray{Float64,1,Array{Float64,1},Axis{:row,Array{String,1}}}  # c^{kWh}_{b}:  Capital cost per unit energy capacity of storage system b [$/kWh]  (NEW)
	 #FuelCost::AxisArray{Float64} # c^{u}_{f}: Unit cost of fuel type f [$/MMBTU]  in math  (NEW)
	 #ElecRate::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,UnitRange{Int64}}}}  #   c^{g}_{uh}: Grid energy cost in energy demand tier u during time step h  (NEW)
	 #GridExportRates::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{Int64,1}}, Axis{:col,UnitRange{Int64}}}}    # c^{e}_{uh}: Export rate for energy in energy pricing tier u in time step h   (NEW)
	 #FuelBurnSlope::AxisArray # m^\text{fm}_{t}: Fuel burn rate slope parameter for technology t
	 #FuelBurnYInt::AxisArray # m^\text{fb}_{t}: Fuel burn rate slope parameter for technology t
	 #MaxGridSales::Array{Float64,1}   # \delta^{gs}_{u}: Maximum allowable energy sales in tier u in math; equal to sum of LoadProfile["1R",ts] on set TimeStep for tier 1 (analogous "1W") and unlimited for "1X"
	 #ProductionIncentiveRate::AxisArray  # i^{r}_{t}: Incentive rate for technology t [$/kWh] (NEW)
	 #ProductionFactor::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,UnitRange{Int64}}}}     #f^{p}_{th}  Production factor of technology t and time step h  [unitless]  (NEW)
	 #ElecLoad::Array{Float64,1}  # \delta^{d}_{h}: Electrical load in time step h   [kW]
	 #FuelLimit::AxisArray # b^{fa}_{f}: Amount of available fuel for type f [MMBTU]   (NEW)
	 #ChargeEfficiency::AxisArray{Float64,2,Array{Float64,2},Tuple{Axis{:row,Array{String,1}},Axis{:col,Array{String,1}}}}  # \eta^{esi}_{bt}: Efficiency of charging storage system b using technology t  [fraction] (NEW)
	 #GridChargeEfficiency::Float64   # \eta^{esig}: Efficiency of charging electrical storage using grid power [fraction] (NEW)
	 #DischargeEfficiency::AxisArray  # \eta^{eso}_{b}: Efficiency of discharging storage system b [fraction] (NEW)
	 #StorageMinSizeEnergy::AxisArray     # \bar{w}^{bkWh}_{b}: Maximum energy capacity of storage system b [kWh] (NEW)
     #StorageMaxSizeEnergy::AxisArray     # \ubar{w}^{bkWh}_{b}: Minimum energy capacity of storage system b [kWh] (NEW)
	 #StorageMinSizePower::AxisArray     # \bar{w}^{bkW}_{b}: Maximum power capacity of storage system b [kW] (NEW)
     #StorageMaxSizePower::AxisArray     # \ubar{w}^{bkW}_{b}: Minimum power capacity of storage system b [kW] (NEW)
     #StorageMinSOC::AxisArray     #  \ubar{w}^{mcp}_{b}: Minimum state of charge of storage system b [fraction] (NEW)
     #StorageInitSOC::AxisArray  #Initial state of charge of storage system b [fraction] (NEW)
	 

	 ### To be replaced  ###
	 Load::Array{String,1}
	 TechIsGrid
	 
	 ### Not used or used for calculation of other parameters ###
	 two_party_factor::Float64 # Not used (?)
     analysis_years::Int64     # Used to calculate present worth factors maybe?
     AnnualElecLoad::Float64   # Not used anymore (can just sum LoadProfile["1R",h] for all h in TimeStep
     CapCostSegCount::Int64    # Size of set S 
     FuelBinCount::Int64       # Size of set F  
     DemandBinCount ::Int64    # Size of set E
     DemandMonthsBinCount::Int64   # Size of set N
     TimeStepCount::Int64          # Size of set H
     Points::UnitRange{Int64}      # CapCostSegCount+1; this is going to be the size of set S^{c} now
     PricingTierCount::Int64    # Size of set U
	 
     # new parameters for reformulation
     StoragePowerCost
     StorageEnergyCost
     FuelCost
     ElecRate
     GridExportRates
     FuelBurnSlope
     FuelBurnYInt
     MaxGridSales
     ProductionIncentiveRate
     ProductionFactor
     ElecLoad
     FuelLimit
     ChargeEfficiency
     GridChargeEfficiency
     DischargeEfficiency
     StorageMinSizeEnergy
     StorageMaxSizeEnergy
     StorageMinSizePower
     StorageMaxSizePower
     StorageMinSOC
     StorageInitSOC
     SegmentMinSize
     SegmentMaxSize

     # New Sets
     Storage
     FuelType
     Subdivision
     ElecStorage
     FuelTypeByTech
     SubdivisionByTech
     SegByTechSubdivision
     TechsChargingStorage
     TechsInClass
     TechsByFuelType
     ElectricTechs
     FuelBurningTechs
     TechsNoTurndown
     SalesTiers
     StorageSalesTiers
     NonStorageSalesTiers

    # Feature Additions
     TechToLocation
     MaxSizesLocation
end


function build_param(d::Dict)
#           Tech,
#           Load,
#           TechClass,
#           TechIsGrid,
#           TechToLocation,
#           MaxSizesLocation,
#           TurbineDerate,
#           NMILRegime,
#           r_tax_owner,
#           r_tax_offtaker,
#           pwf_om,
#           pwf_e,
#           pwf_prod_incent,
#           LevelizationFactor,
#           LevelizationFactorProdIncent,
#           StorageCostPerKW,
#           StorageCostPerKWH,
#           OMperUnitSize,
#           CapCostSlope,
#           CapCostYInt,
#           CapCostX,
#           MaxProdIncent,
#           MaxSizeForProdIncent,
#           two_party_factor,
#           analysis_years,
#           AnnualElecLoad,
#           LoadProfile,
#           StorageMinChargePcent,
#           InitSOC,
#           MaxSize,
#           MinStorageSizeKW,
#           MaxStorageSizeKW,
#           MinStorageSizeKWH,
#           MaxStorageSizeKWH,
#           TechClassMinSize,
#           MinTurndown,
#           FixedMonthlyCharge,
#           AnnualMinCharge,
#           MonthlyMinCharge,
#           ExportRates,
#           TimeStepRatchetsMonth,
#           DemandRatesMonth,
#           DemandLookbackPercent,
#           MaxDemandInTier,
#           MaxDemandMonthsInTier,
#           MaxUsageInTier,
#           NMILLimits,
#           TechToNMILMapping,
#           DemandRates,
#           TimeStepRatchets,
#           DemandLookbackMonths,
# 		  TimeStepsWithGrid,
#           TimeStepsWithoutGrid,
#           CapCostSegCount,
#           FuelBinCount,
#           DemandBinCount ,
#           DemandMonthsBinCount,
#           TimeStepCount,
#           NumRatchets,
#           TimeStepScaling,
#           OMcostPerUnitProd,
# 	      StoragePowerCost,
# 	      StorageEnergyCost,
# 	      FuelCost,
# 	      ElecRate,
# 	      GridExportRates,
# 	      FuelBurnSlope,
# 	      FuelBurnYInt,
# 	      MaxGridSales,
# 	      ProductionIncentiveRate,
# 	      ProductionFactor,
# 	      ElecLoad,
# 	      FuelLimit,
# 	      ChargeEfficiency,
# 	      GridChargeEfficiency,
# 	      DischargeEfficiency,
# 	      StorageMinSizeEnergy,
# 	      StorageMaxSizeEnergy,
# 	      StorageMinSizePower,
# 	      StorageMaxSizePower,
# 	      StorageMinSOC,
# 	      StorageInitSOC,
# 		  SegmentMinSize,
#           SegmentMaxSize,
#           Storage,
#           FuelType,
#           Subdivision,
#           PricingTierCount,
#           ElecStorage,
#           FuelTypeByTech,
#           SubdivisionByTech,
#           SegByTechSubdivision,
#           TechsChargingStorage,
#           TechsInClass,
#           TechsByFuelType,
#           ElectricTechs,
#           FuelBurningTechs,
#           TechsNoTurndown,
#           SalesTiers,
#           StorageSalesTiers,
#           NonStorageSalesTiers,
#           kwargs...
    can_be_empty = (
        "MaxSize",
        "OMperUnitSize",
        "OMcostPerUnitProd",
        "MaxProdIncent",
        "MaxSizeForProdIncent",
        "TurbineDerate",
        "MinTurndown",
        "pwf_prod_incent",
        "LevelizationFactor",
        "LevelizationFactorProdIncent",
        "NMILLimits",
        "TurbineDerate",
        "TechClassMinSize"
     )
    if typeof(d["Tech"]) === Array{Any, 1}  # came from Python as empty array
        d["Tech"] = convert(Array{String, 1}, d["Tech"])
    end
    for x in can_be_empty
        if typeof(x) === Array{Any, 1}  # came from Python as empty array
            d[x] = convert(Array{Float64, 1}, d[x])
        end
    end
    Seg = 1:d["CapCostSegCount"]
    Points = 0:d["CapCostSegCount"]
    Month = 1:12
    Ratchets = 1:d["NumRatchets"]
    FuelBin = 1:d["FuelBinCount"]
	PricingTier = 1:d["PricingTierCount"]
    DemandBin = 1:d["DemandBinCount"]
    DemandMonthsBin = 1:d["DemandMonthsBinCount"]
    TimeStep = 1:d["TimeStepCount"]
    TimeStepBat = 0:d["TimeStepCount"]
	#Subdivision=1:1
	#FuelType = 1:d["FuelBinCount"]
	#Storage = 1:1
    Location = 1:3

    TechIsGrid = parameter(d["Tech"], d["TechIsGrid"])
    TurbineDerate = parameter(d["Tech"], d["TurbineDerate"])
    TechToLocation = parameter((d["Tech"], Location), d["TechToLocation"])
    pwf_prod_incent = parameter(d["Tech"], d["pwf_prod_incent"])
    LevelizationFactor = parameter(d["Tech"], d["LevelizationFactor"])
    LevelizationFactorProdIncent = parameter(d["Tech"], d["LevelizationFactorProdIncent"])
    OMperUnitSize = parameter(d["Tech"], d["OMperUnitSize"])
    CapCostSlope = parameter((d["Tech"], Seg), d["CapCostSlope"])
    CapCostYInt = parameter((d["Tech"], Seg), d["CapCostYInt"])
    CapCostX = parameter((d["Tech"],Points), d["CapCostX"])
    MaxProdIncent = parameter(d["Tech"], d["MaxProdIncent"])
    MaxSizeForProdIncent = parameter(d["Tech"], d["MaxSizeForProdIncent"])
    MaxSizesLocation = parameter(Location, d["MaxSizesLocation"])
    LoadProfile = parameter((d["Load"], TimeStep), d["LoadProfile"])
    MaxSize = parameter(d["Tech"], d["MaxSize"])
    TechClassMinSize = parameter(d["TechClass"], d["TechClassMinSize"])
    MinTurndown = parameter(d["Tech"], d["MinTurndown"])
    TimeStepRatchets = emptySetException(Ratchets, d["TimeStepRatchets"])
    DemandRates = emptySetException((Ratchets, DemandBin), d["DemandRates"], true)
    ExportRates = parameter((d["Tech"], d["Load"], TimeStep), d["ExportRates"])
    TimeStepRatchetsMonth = parameter(Month, d["TimeStepRatchetsMonth"])
    DemandRatesMonth = parameter((Month, DemandMonthsBin), d["DemandRatesMonth"])
    MaxDemandInTier = parameter(DemandBin, d["MaxDemandInTier"])
    MaxDemandMonthsInTier = parameter(DemandMonthsBin, d["MaxDemandMonthsInTier"])
    MaxUsageInTier = parameter(FuelBin, d["MaxUsageInTier"])
    NMILLimits = parameter(d["NMILRegime"], d["NMILLimits"])
    TechToNMILMapping = parameter((d["Tech"], d["NMILRegime"]), d["TechToNMILMapping"])
    OMcostPerUnitProd = parameter(d["Tech"], d["OMcostPerUnitProd"])

    # Reformulation additions
    StoragePowerCost = parameter(d["Storage"], d["StoragePowerCost"])
    StorageEnergyCost = parameter(d["Storage"], d["StorageEnergyCost"])
    FuelCost = parameter(d["FuelType"], d["FuelCost"])
    ElecRate = parameter((PricingTier, TimeStep), d["ElecRate"])
    GridExportRates = parameter((PricingTier, TimeStep), d["GridExportRates"])
    FuelBurnSlope = parameter(d["Tech"], d["FuelBurnSlope"])
    FuelBurnYInt = parameter(d["Tech"], d["FuelBurnYInt"])
    MaxGridSales = parameter(PricingTier, d["MaxGridSales"])
    ProductionFactor = parameter((d["Tech"], TimeStep), d["ProductionFactor"])
    ProductionIncentiveRate = parameter(d["Tech"], d["ProductionIncentiveRate"])
    ElecLoad = parameter(TimeStep, d["ElecLoad"])
    FuelLimit = parameter(d["FuelType"], d["FuelLimit"])
    ChargeEfficiency = parameter((d["Tech"], d["Storage"]), d["ChargeEfficiency"]) # does this need to be indexed on techs?
    GridChargeEfficiency = parameter(d["Storage"], d["GridChargeEfficiency"])
    DischargeEfficiency = parameter(d["Storage"], d["DischargeEfficiency"])
    StorageMinSizeEnergy = parameter(d["Storage"], d["StorageMinSizeEnergy"])
    StorageMaxSizeEnergy = parameter(d["Storage"], d["StorageMaxSizeEnergy"])
    StorageMinSizePower = parameter(d["Storage"], d["StorageMinSizePower"])
    StorageMaxSizePower = parameter(d["Storage"], d["StorageMaxSizePower"])
    StorageMinSOC = parameter(d["Storage"], d["StorageMinSOC"])
    StorageInitSOC = parameter(d["Storage"], d["StorageInitSOC"])
    SegmentMinSize = parameter((d["Tech"], d["Subdivision"], Seg), d["SegmentMinSize"])
    SegmentMaxSize = parameter((d["Tech"], d["Subdivision"], Seg), d["SegmentMaxSize"])

    # Indexed Sets
    SegByTechSubdivision = parameter((d["Subdivision"], d["Tech"]), d["SegByTechSubdivision"])
    TechsByFuelType = len_zero_param(d["FuelType"], d["TechsByFuelType"])
    FuelTypeByTech = len_zero_param(d["Tech"], d["FuelTypeByTech"])
    SubdivisionByTech = len_zero_param(d["Tech"], d["SubdivisionByTech"])
    TechsInClass = len_zero_param(d["TechClass"], d["TechsInClass"])

    param = Parameter(
                d["TechClass"],
                DemandBin,
                TimeStep,
                TimeStepBat,
                Month,
                DemandMonthsBin,
                Ratchets,
                Seg,
                d["Tech"],
                FuelBin,
				PricingTier,
                d["NMILRegime"],

                TimeStepRatchetsMonth,
                TimeStepRatchets,
				d["TimeStepsWithGrid"],
                d["TimeStepsWithoutGrid"],
                
                d["DemandLookbackMonths"],

                TechToNMILMapping,
                d["TimeStepScaling"],

                d["AnnualMinCharge"],
                d["MonthlyMinCharge"],
                d["FixedMonthlyCharge"],
                d["StorageCostPerKW"],
                d["StorageCostPerKWH"],

                OMperUnitSize,
                OMcostPerUnitProd,

                ExportRates,
                CapCostSlope,
                CapCostYInt,
                CapCostX,
                DemandRates,
                DemandRatesMonth,

                LoadProfile,
                d["DemandLookbackPercent"],
                MaxDemandInTier,
                MaxDemandMonthsInTier,
                MaxUsageInTier,

                NMILLimits,
                MaxProdIncent,
                MaxSizeForProdIncent,

                TurbineDerate,
                MinTurndown,
                pwf_prod_incent,
                LevelizationFactor,
                LevelizationFactorProdIncent,

                d["pwf_om"],
                d["pwf_e"],
                d["r_tax_owner"],
                d["r_tax_offtaker"],

                TechClassMinSize,
                MaxSize,

                d["MinStorageSizeKWH"],
                d["MaxStorageSizeKWH"],
                d["MinStorageSizeKW"],
                d["MaxStorageSizeKW"],
                d["StorageMinChargePcent"],
                d["InitSOC"],

                d["Load"],
                TechIsGrid,

                d["two_party_factor"],
                d["analysis_years"],
                d["AnnualElecLoad"],
                d["CapCostSegCount"],
                d["FuelBinCount"],
                d["DemandBinCount"],
                d["DemandMonthsBinCount"],
                d["TimeStepCount"],
                Points,
                d["PricingTierCount"],

                StoragePowerCost,
                StorageEnergyCost,
                FuelCost,
                ElecRate,
                GridExportRates,
                FuelBurnSlope,
                FuelBurnYInt,
                MaxGridSales,
                ProductionIncentiveRate,
                ProductionFactor,
                ElecLoad,
                FuelLimit,
                ChargeEfficiency,
                GridChargeEfficiency,
                DischargeEfficiency,
                StorageMinSizeEnergy,
                StorageMaxSizeEnergy,
                StorageMinSizePower,
                StorageMaxSizePower,
                StorageMinSOC,
                StorageInitSOC,
                SegmentMinSize,
                SegmentMaxSize,

                d["Storage"],
                d["FuelType"],
                d["Subdivision"],
                d["ElecStorage"],
                FuelTypeByTech,
                SubdivisionByTech,
                SegByTechSubdivision,
                d["TechsChargingStorage"],
                TechsInClass,
                TechsByFuelType,
                d["ElectricTechs"],
                d["FuelBurningTechs"],
                d["TechsNoTurndown"],
                d["SalesTiers"],
                d["StorageSalesTiers"],
                d["NonStorageSalesTiers"],

                TechToLocation,
                MaxSizesLocation
        )

    return param

end

# Code for parameter() function
function paramDataFormatter(setTup::Tuple, data::AbstractArray)
    if typeof(data) === Array{Any, 1}
        data = convert(Array{Float64, 1}, data)
    end
    reverseTupleAxis = Tuple([length(set) for set in setTup][end:-1:1])
    shapedData = reshape(data, reverseTupleAxis)
    reverseDataAxis = [length(setTup)+1 - n for n in 1:length(setTup)]
    shapedDataT = permutedims(shapedData, reverseDataAxis)
    return AxisArray(shapedDataT, setTup)
end

function parameter(setTup::Tuple, data::AbstractArray)
    #data = retype(nondata)
    try
        formattedParam = paramDataFormatter(setTup, data)
        return formattedParam
    catch
        correctLength = prod([length(x) for x in setTup])
        if length(data) < correctLength
            let x = 1
                for set in setTup
                    x = x * length(set)
                end
                numZeros = x - length(data)
                for zero in 1:numZeros
                    append!(data, 0)
                end
                formattedParam = paramDataFormatter(setTup, data)
                return formattedParam
            end
        else
            data = data[1:correctLength]
            formattedParam = paramDataFormatter(setTup, data)
            return formattedParam
        end
    end
end

function parameter(set::UnitRange{Int64}, data::Float64)
    return [data]
end

function parameter(setTup::Tuple{Array{Symbol,1}, UnitRange{Int64}}, data::Number)
    newTup = ([setTup[1][1], :FAKE], 1:2)
    return AxisArray(fill(data, 2, 2), newTup)
end

function parameter(set::Symbol, data::Int64)
    return AxisArray([data], set)
end

"""
    function parameter(set::Array{Any, 1}, data::Array{Any, 1})

For empty data and set, convert to appropriate types for Parameter struct
"""
function parameter(set::Array{Any, 1}, data::Array{Any, 1})
    data = convert(Array{Float64,1}, data)
    set = convert(Array{String,1}, set)
    shapedData = reshape(data, length(set))
    return AxisArray(shapedData, set)
end

function parameter(set, data)
    shapedData = reshape(data, length(set))
    return AxisArray(shapedData, set)
end

# Additional dispatches to make things easier
function length(::Symbol)
    return 1
end

function reshape(data::Number, axes::Int64)
    return data
end

function AxisArray(data::Number, index::Array{Symbol, 1})
    return AxisArray([float(data)], index)
end

function AxisArray(data::Float64, index::Array{String, 1})
    return AxisArray([float(data)], index)
end

function AxisArray(data::Int64, index::Array{String, 1})
    return AxisArray([float(data)], index)
end

function JuMP.value(::Val{false})
    return 0.0
end

function JuMP.value(x::Float64)
    return x
end

function len_zero_param(sets, arr::Array)
    try
        if length(arr) == 0
            dims = setdiff(size(arr), 0)
            zero_array = Array{Array}(undef, dims...)
            return parameter(sets, zero_array)
        else
            return parameter(sets, arr)
        end
    catch
        println("Empty Array Created")
        return []
    end
end
