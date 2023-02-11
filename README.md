# evolution-climate-change

This NetLogo model simulates trait-based biotic responses to climate change in an environmentally heterogeneous continent in an evolving clade, the species of which are each represented by local populations that disperse and interbreed; they also are subject to selection, genetic drift, and local extirpation. We simulated mammalian herbivores, whose success depends on tooth crown height, vegetation type, precipitation and grit. This model investigates the role of dispersal, selection, extirpation, and other factors contribute to resilience under three climate change scenarios.

This model was the basis of a [publication](https://pollylab.indiana.edu/doc/Mo-and-Polly,-2022,-risk-and-resilience-to-climate-change.pdf) in Global Ecology and Biogeography. To see a full list of citations as well as the model findings, please refer to this paper.

# Model overview
This agent-based model (ABM) simulates trait-based population-level responses to
climatic and environmental change. The premise of ABMs lies in the principle that micro-level
agent-agent and agent-environment interactions produce emergent macro-level outcomes for
systems too complex or too specific to model with standard structural equations (Tisue &
Wilensky, 2004). Our rule-based ABM simulates the fates of metapopulations whose fitness is
controlled by an evolving functional trait that responds to selection based on environmental
conditions. Functional traits are phenotypic characteristics that interface with the environment
(McGill et al., 2006; Polly et al., 2016). Environmental change potentially affects trait
performance and population fitness, consequently driving trait evolution or population
extinction., which in turn affects functional trait distribution in local community assemblages
(Jønsson et al., 2015; Morales-Castilla et al., 2015; Polly & Head, 2015).
The functional trait modeled is tooth crown height of mammalian herbivores, such as
horses. The evolution of high-crowned teeth in these herbivores is climatically driven; in fact, the
relationship between crown height, environment, and climate is well-understood both
functionally and evolutionarily (Damuth & Janis, 2011; Eronen et al., 2010; Fortelius et al.,
2002; King et al., 2005; Semprebon et al., 2019). In environments with abrasive or dusty/gritty
vegetation, higher-crowned (hypsodont) teeth provide greater fitness despite the metabolic and
mineral costs of producing them. The silica content of grass and gritty arid environments select
for hypsodonty; non-gritty forests select for brachydonty (low-crowned teeth). Although the
specifics of our model are teeth, diet, and environment, the implementation is abstract enough
that results can be generalized to other climate-environment-trait systems.
Our virtual world consists of a continent that is gridded in spatially distinct habitat
“patches.” Each patch denotes a local environment, which determines the local fitness optimum
for inhabitant populations. Each “agent” in this model represents one local population of a
species. Each species can consist of many populations, each of which occupies a single patch,
thus making them the equivalent of metapopulations (sensu Hanski, 1999). A patch can be
occupied by a maximum of one agent of any given species—the same patch can be occupied by
multiple agents, given that the agents are of different species. Each individual run is divided into
temporally distinct “time steps.”

Our model incorporates five key processes: climate change, dispersal (including gene
flow), selection, speciation, and extirpation. Model parameters can be adjusted for each of these
mechanisms except for speciation, which we treat as a constant process so that our model runs
end with a predictable number of species with identical patterns of common ancestry and
divergence times so that variance between model runs is due only to change in climate and the
aforementioned controllable demographic parameters. Populations do not compete with one
another; similarly, this helps the model largely focus on population-environment interactions in a
changing climate. During each time step, each local population undergoes selection, dispersal,
and the possibility of extirpation. (Populations also undergo genetic drift.) Speciation events act
at predetermined time steps. Additionally, climate change periodically produces shifts in
precipitation and biome type that influence the selective optimum for patches. The crux of the
model lies in the interaction of these mechanisms. Adjusting parameters either independently or
simultaneously allows us to test which combinations confer resilience under gradual, moderate,
or rapid climatic change scenarios. For the purposes of this model, we measure resilience via
three metrics: number of species existing at the end of each model run (species number), number
of populations of each species (species abundance), and successful colonization of new biomes
that arise during the run.

Our ABM extends Polly et al. (2016)’s trait-climate-environment model in two important
ways. This model integrates climate change and dynamic environments; the previous model was
limited to static environments. Additionally, we have ported the model to NetLogo 6.1.1.
Underlying mechanics remain consistent with the earlier model. Readers are referred to it for full
justification of implementation and parameter choices.

## NetLogo
NetLogo is an ABM programming environment suitable for simulating spatially and
temporally explicit phenomena (Tisue & Wilensky, 2004; Wilensky, 1999). Spatial settings and
rules for agent behavior are highly customizable (Tisue & Wilensky, 2004). We used NetLogo’s
BehaviorSpace tool to record the numerical output of each model run; spatial results were
identified through model interface images.

## Model algorithm
Each individual run lasts for 400 time-steps. Several parameters—selection intensity
(adaptive peak width), phenotypic variance, trait heritability, dispersal probability, and
extirpation probability—can be adjusted in the setup. Populations undergo extirpation, dispersal,
selection, gene flow, and genetic drift every time step; speciation occurs every 100 steps.

## Model world and characteristics of patches
The model world consists of the virtual continent, Hesperia, with varied topography.
Hesperia is divided into 822 spatially distinct square patches, each of which is assigned values
for grit, temperature, and mean annual precipitation. Patches are categorized into vegetative
biomes (tundra, forest, desert, or grassland) based on temperature and precipitation (Whittaker,
1967). In this way, Hesperia is environmentally heterogeneous. Local selective optimums for
hypsodonty values are calculated based on grit, precipitation, and biome type. Climate becomes
more arid as the model progresses, transforming forest into grassland and desert and shifting
selective optimums.

We determined biome type (grassland, tundra, forest, or desert) from a function of
temperature and precipitation following Whitaker (1967). If temperature ≤ -5 °C, the patch is
categorized as tundra biome. If temperature > -5 °C and precipitation ≤ 20 cm/year, the patch
biome is categorized as desert. If temperature ≥ 5 °C and precipitation > 20 cm but ≤ 90 cm, the
biome is categorized as grassland. All other patches are classified as forest biomes.

## Characteristics of populations
Each local population is represented in NetLogo using an agent called a “turtle.” Each
population is assigned numerical characteristics: ID number, species assignment, trait value, and
population size (number of individuals, which determines rate of genetic drift). Population trait
value represents the population mean. For consistency with the 2016 model, population size is
set to 100 individuals. Names assigned to species in the model output indicate species ancestry
and the model step at which it originated.

## Functional trait and its local optimum
Tooth crown height is our functional trait. In mammals, crown height varies with
environmental parameters affecting diet abrasiveness. The selective optimum (ideal trait value)
in any local environment (patch) is a function of grit g, precipitation p, and biome b. The
optimum ranged from 0 (low-crowned or brachydont) to 3 (high-crowned or hypsodont). Highcrowned teeth are more suited to dry and gritty environments and tough vegetation; in contrast,
low-crowned teeth are more suited to wet environments with little grit and tender vegetation
(Janis and Fortelius, 1988; Damuth and Janus, 2011). Following Polly et al. (2016), the local
selective optimum, 𝜃i, for each patch was set as a function of precipitation, biome, and grit,
where 𝑔 is grit, p is precipitation, and b is biome.
𝜃i = 𝑔 + 𝛿[𝑝] + 𝛿[𝑏] ,
where 𝛿[𝑝] is the piecewise function:
For 𝑝 ≤ 100, 𝛿[𝑝] = 100 - p
For 𝑝 > 100, 𝛿[𝑝] = 0
and 𝛿[𝑏] is the piecewise function:
For b = “forest” or “tundra”, 𝛿[𝑏] = 0
For b = “desert”, 𝛿[𝑏] = 0.5
For b = “grassland”, 𝛿[𝑏] = 1

Population fitness is determined by proximity of mean functional trait value and local
selective optimum of the occupied patch. Smaller differences between the actual and optimal
trait value indicate higher fitness.

## Extirpation
Extirpation is the local extinction of a population from a patch. Species extinction occurs
if all local populations of the species are extirpated. Extirpation occurs stochastically, with a
greater probability p(e) in populations with trait value far from local optimum:
p(e) = ESF * |z - θi| / APW
where z is population trait value, θi is local selective optimum, ESF is extirpation scaling factor
(a user-controllable parameter ranging from 0 to infinity), and APW is adaptive peak width
(selection intensity; see below). Essentially, if trait value is far from the selective optimum
relative to selection intensity, extirpation probability increases toward 1.0. Setting ESF < 1
decreases the probability, whereas setting ESF > 1 increases it. This method is comparable to the
Lynch and Lande (1993) function and identical to that of Polly et al. (2016).

## Dispersal
During a dispersal event, a turtle creates a copy of itself on an adjacent terrestrial patch.
The user-controllable dispersal probability parameter (ranges from 0 to 1) determines probability
of dispersal into an individual adjacent terrestrial patch.

## Selection and genetic drift
Each step, the trait value of each population is modified by selection:

z_new = (z_old(θ_i - z_old) / w^2)) * h^2 * v

where z_old is trait value before selection, θi is local selective optimum, w2
is adaptive peak width
(equal to standard deviation of the normal curve used to model the adaptive peak), h2
is
heritability, and v is phenotypic variance. This equation, used in Polly et al. (2016), comes from
theoretical evolutionary genetics models of adaptive peaks (Arnold et al., 2001; Lande, 1976;
Simpson, 1944).
Each trait value is further modified by a neutral genetic drift event. The genetic drift term
is randomly chosen from a normal distribution with mean 0 and standard deviation h2 v / N,
where h2
is heritability, v is phenotypic variance, and N is population size. This standard
deviation derives from Lande (1976). The genetic drift value is added to znew.

## Genetic flow
Each patch can only support one turtle of each species. After dispersal, if two or more
populations of the same species occupy the same patch, gene flow between populations occurs.
The amalgamated population takes on the mean of the populations occupying the patch and the
local population size is reset to 100.

## Speciation
Speciation via a simplified peripheral isolation model occurs at time-steps 0, 100, 200,
and 300 (Polly et al., 2016). Every species undergoes the same speciation process. First, the most
peripheral turtle of each species is determined. The mean x-coordinate (xmean) and mean ycoordinate (ymean) of all turtles of species k represent the geographic center of the species range.
The population located farthest from the center (determined by Euclidean distance) becomes the
founder of a new species on the same patch. The “child” population is identical to the “parent.”
The four speciation events will result in a maximum of 16 species at the end of the run.
Species are named systematically. The progenitor population is designated species 1. The
first speciation event creates species 2. For future speciation events, the “child” population is
named species (2x + 1), where x is the current species name. The “parent” population is
designated species (2x + 2). For example, at 100 time-steps, species 1 produces species 3. All
populations of species 1 are relabeled as species 4.

## Tracking variables
Utilizing NetLogo’s BehaviorSpace tool, relevant population-related variables were
recorded during each time-step. For the aggregate of all populations on the continent, the mean
trait value and standard deviation of trait value were recorded. On the species level, the number
of populations, mean trait value and standard deviation of trait value were recorded. The number
of existing species was also tracked.
For each patch, the average trait value of all species, trait value of individual species, and
species richness (number of occupant species) were also reported during each time step.
A species was considered to have colonized a region if 5 patches of the region were occupied by
run’s end.

## Barriers to dispersal
Barriers to dispersal in our model are emergent properties from the interaction of
environmental parameters, selection intensity, extirpation risk, and dispersal rate. A population
can disperse into any adjacent grid cell regardless of the parameters, but if the trait optimum is
substantially different in the new location there is a high probability of immediate extirpation
because of low fitness. While the mountains are not modeled as physical barriers, they produce
environmental barriers because of their rain shadow, grit cloud, and temperature gradient (which
along with precipitation determines vegetation biome). If extirpation scaling factor is low or if
adaptive peak width is high (i.e., weak selection) an environmental gradient will pose less of a
barrier because a poorly adapted population can still survive. Because extirpation is modeled as a
probability rather than a certainty, even a step environmental gradient can be breached by chance
if the dispersal rate is high enough. Rate of dispersal affects the likelihood of eventual success
because it determines the number of times a population ventures into a cell where it has low
fitness. The only impassible physical barriers are the oceans at the continental margins.

# Climate change modeling

## Climate change mechanics
We modeled three scenarios of climate change (gradual, moderate, and rapid) by altering
annual precipitation, which influences biome type as well as the local selective optimum. At
predetermined time steps, all patches decrease precipitation levels by a preset amount. All model
runs, regardless of the rate of climate change, begin and end with all patches on Hesperia having
the same environment. Each model starts with high precipitation such that most Hesperian
patches possess forest biomes, with few tundra patches at high elevations. By the end of the
model, precipitation across all patches decreases by 200 cm and most patches have changed to
desert. In the gradual climate change scenario, precipitation decreases 5.13 cm every ten steps, in
the moderate scenario it decreases 28.57 cm of the total change every 50 steps, and in the rapid
scenario the precipitation decreases 100 cm twice during the run. Minimum precipitation is
floored at 0 cm per year. During climate change events, each patch’s biome type is reclassified
using the previously described method. Then, the ideal trait value of each patch is also
recalculated.

# Experiments
We conducted four experiments varying demographic parameters, each repeated across
three different climate change scenarios. Experiment A varied dispersal with consistently high
extirpation (DISP varies between 0 and 1.0, APW = 1.0, ESF = 2.0). Experiment B varied
dispersal under consistently low extirpation (DISP varies between 0 and 1.0, APW = 1.0, ESF =
1.0). Experiment C varied ESF under high dispersal (ESF varies between 0 and 2.0, APW = 1.0,
and DISP = 1.0). Experiment D varied APW under high ESF and high dispersal (APW varies
between 0 and 3.0, ESF = 2.0, DISP = 1.0). An alteration of Experiment D varied APW under
low ESF and high dispersal (APW varies between 0 and 3.0, ESF = 1.0, DISP = 1.0). See
Extended Results & Figure 3 for selected model output and Files S3 for detailed results on
each model run.

# How to Install and Run
This model runs on NetLogo 6.1.1. To ensure that the model can run, first download the geography_input.txt file and modify the indicated input and output file paths in the NetLogo code to a local destination on your workstation. Next, press the **setup** button on the **Interface** tab. To run the model stepwise, press the **go once** button on the **Interface** tab. To run the model until its stopping point, press the **go** button on the **Interface** tab.

# Collaborators
P. David Polly, Professor and Chair, Department of Earth and Atmospheric Sciences

# License
Distributed under the MIT License.
