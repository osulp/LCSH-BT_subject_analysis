# LCSH Broader Terms Subject Analysis

This repository contains several XSLT 2.0 stylesheets run in sequence against a local copy of the Library of Congress Subject Headings (LCSH) in SKOS RDF format. The pipeline constructs a model of progressively broader subject headings for a given collection of library materials based on the LC subject terms found in the collection's metadata records (e.g. MARC catalog records, EAD finding aids, Dublin Core records, etc.). The repository includes tools to analyze and present the resulting model. 



## Background

Broader terms (BTs) and narrower terms (NTs) are used by LCSH to organize subject headings and relate them to one another. LC's Subject Heading Manual, [H 370](https://www.loc.gov/aba/publications/FreeSHM/H0370.pdf) provides the following background: 

> Broader term, narrower term, and related term references for subject headings are created according to the following principles (H 370, p.1):
> Hierarchical references. A narrower term reference is made to a given subject heading from the next broader heading so that terms are arranged in a hierarchy. The following relationships are considered hierarchical:
> - Genus/species (or class/class member) [...]
> - Whole/part [...]
> - Instance (or generic topic/proper-named example) [...]

By tracing the "tree" of broader terms from the subject headings assigned to a particular library collection until they terminate at their theoretical broadest concept -- what H 370 refers to as "top terms" -- we can construct a model of the general topics present in that collection and observe relationships between subjects and the resources to which they are assigned. 

This method was developed to create a baseline topic model for a research article _Text analysis of archival finding aids_, which is pending publication in _Information Technology and Libraries_ as of August 2024. The final topic model produced for that project using this method is contained in the supplementary OSF repository: 

> Bahde, A. & Key, C. (2024b). Text analysis of archival finding aids: Supporting materials [Dataset]. Open Science Framework. http://doi.org/10.17605/OSF.IO/AUXF4

## Requirements

- Requires an XSLT 2.0 processor. Can be run with an application such as oXygen but a command line tool is recommended. Commands are given below using Saxon; see https://www.saxonica.com/.
  - The `../saxon.jar` file referenced in the commands below is a symbolic link, located in the parent directory, to the Saxon JAR file. Update commands as needed to point to the location and filename for your local JAR file.
- Requires a local copy of Library of Congress Subject Headings (LCSH) serialized as SKOS/RDF XML, which is obtained from LC's Linked Data Service Bulk Downloads page at https://id.loc.gov/download/.
  - In order to use the LCSH file as valid XML, the repeated XML declaration and the `rdf:RDF` wrapper element must be stripped from individual authority records, keeping them only at the top/root level of the XML file. This can be achieved by various techniques; the author used the find/replace function in a text editor.
  - Be sure to update the LCSH filename and path found at the top of `step1_bt_merger.xsl` to point to your local copy.
- Requires a source collection of digital metadata records containing Library of Congress Subject Headings.
  - The current version of the pipeline only handles EAD XML files as the source metadata; it includes a separate stylesheet to fetch LCSH terms from EAD XML files (per the use case for which this pipeline was originally developed). Retooling will be needed for any other type of source metadata. 

## Conventions

### Terminology

While all "subjects" and "topics" present throughout the pipeline should be LCSH terms, the following naming system is used to disambiguate:  

  - **Subjects** are LCSH terms as they originally occur in the source collection
  - **Topics** are LCSH terms that constitute the model built by this pipeline.
  - **Subject heading** refers to an individual entry in LCSH.
  - **Term** may be used interchangeably with Subject heading for an individual entry in LCSH, but is also be used to refer to an individual Topic entry in the model.
  - **Broader Terms** are found within an LC subject authority record (as defined above in "Background").
  - **Label** refers specifically to the human-readable string representing the Subject, Topic, etc.; the label may be the de facto representation of a term for most purposes, but it's worth mentioning that an LCSH term (in the Linked Data Service) is also represented by a permanent/fixed machine-readable URI, while the label may be subject to change.
  - **Terminus** refers to an LCSH term that has no broader terms, serving as the end point of a hierarchical line. Usually this will be what LC H 370 refers to as a "top term" -- "that is, the broadest topic in a given hierarchy, for example, Science" (H 370, p.3) -- but may be another type of "orphan heading" -- "that is, headings having no BT" (H 370, p.3).
  - **Root subject** is the portion of the subject heading label preceeding the first subdivision, or the sub-string up to the first double hyphen "--" in the label, if present. If not subdivided, the "root subject" is the full subject heading label minus ending punctuation. 

### Processing and file conventions

- To avoid errors when traversing through LCSH Broader Terms, the "root subject" is the only part of a given subject heading that is used in the pipeline. 
- Output files include the iteration number {i} and the step number at the beginning of the filename, for organizing the various XML files generated throughout the pipeline.
- Output files use arbitrary XML in no namespace, but should validate.
- Output files from _step3_ and _step4_ include a `<meta>` section at the top, showing counts of various aspects of the stage, which can be used for tracking and troubleshooting.
- References to the filename `x.xml` in the commands below are for a file that does not exist. The Saxon XSLT command requires an output parameter, but the output filename is specified within the XSLT stylesheet and will override the dummy filename in the command.
- Examples in this README are derived from Oregon State University's Special Collections and Archives Research Center's public collection of finding aids, from the project mentioned above. 

## Usage 

### Setup: Fetch LCSH terms from source metadata 

#### EAD XML

- Set up a single directory of EAD XML files as the source collection.
  - As written, the setup XSLT expects the directory to be located at `../source_xml/ead_xml`, so use this structure or update the variables at the top of the XSLT. 
- Run `setup_fetch_EAD_subjects.xsl` to fetch LC Subject Headings from the EAD XML files:  

```
java -jar ../saxon.jar -s:setup_fetch_EAD_subjects.xsl -xsl:setup_fetch_EAD_subjects.xsl -o:x.xml
```

- The output `0_all_ead_lcsh.xml` should contain one `subject` entry containing the "root subject" for every LCSH term found in the source collection.
  - The `subject_list/subject/root_subject` XPATH are the key components of this file for continuing through the pipeline. The additional elements under `subject` may be used for validation and sanity checking.

Example:

```xml
   <subject>
      <archon_id>1378</archon_id>
      <full_subject>Timber--Oregon.</full_subject>
      <root_subject>Timber</root_subject>
      <type>LCSH</type>
   </subject>
```

### Initialize topics

- Run `step0_initialize_topics.xsl` on the output of the setup step to generate the initial list of topic terms, constituting the most specific or lowest level of the model.
- For EAD, use:  

```
java -jar ../saxon.jar -s:0_all_ead_lcsh.xml -xsl:step0_initialize_topics.xsl -o:x.xml
```

- The output `0-4_topic_list.xml` gives a list of topics equating to the unique root subjects in the collection, with a count of the occurrences of each.

Example:  

```xml
   <topic>
      <label>Timber</label>
      <occurrences self_or_subdiv="14"/>
   </topic>
```

### Pipeline: Construct a topic model using LC Broader Terms

The pipeline consists of four steps run in sequence, then repeated over as many iterations as needed until all original subject headings are traced to their terminus. Terms retain information about their narrower terms, tracing back to the original subject headings, throughout the pipeline. Once a terminus term is identified, it is marked as such and copied through the rest of the pipeline without additional attempts to fetch its broader terms. 

Pipeline examples below are from the first iteration of processing, for brevity. These trace the original subject heading "Timber" to its immediate broader terms, and then one of those broader terms "Forest products" to its broader term "Botany, economic." Term entries become complex very quickly; a later-iteration example is included in the repository [as a separate XML file](/example_topic-list_biology-economic.xml). _This file represents a single top-level topic, "Biology, economic," and all of its narrower hierarchy chains, resulting from step 4 of the 13th and final iteration of the original project._

1. Look up the LCSH entry in the LC SKOS/RDF XML file for each term in the current iteration's topic list; return its URI and broader terms.
  - Run `step1_bt_fetcher.xsl` on the output of either the Initialize Topics setup step or step 4 of the previous iteration, `{i}-4_topic_list.xml`.
  - The output `{i}-1_fetched_bts.xml` includes an `<LC_subject>` element for each topic term, showing its URI, label, number of occurrences in the original collection, its chain of narrower terms, and URIs and labels for each of its newly-fetched broader terms.

Example:

```xml
   <LC_subject>
      <uri>http://id.loc.gov/authorities/subjects/sh85135386</uri>
      <label>Timber</label>
      <occurrences self_or_subdiv="14"/>
      <broader_terms>
         <term>
            <uri>http://id.loc.gov/authorities/subjects/sh85017740</uri>
            <label>Building materials</label>
         </term>
         <term>
            <uri>http://id.loc.gov/authorities/subjects/sh85050613</uri>
            <label>Forest products</label>
         </term>
         <term>
            <uri>http://id.loc.gov/authorities/subjects/sh85078814</uri>
            <label>Lumber trade</label>
         </term>
      </broader_terms>
   </LC_subject>
```

2. Move the model up a hierarchical level by rearranging the list to focus on the new terms fetched in step 1.  
  - Run `step2_bt_rearranger.xsl` on the output of step 1, `{i}-1_fetched_bts.xml`.
  - The output `{i}-2_bt_list.xml` includes a `<broader_term>` entry for each broader term fetched in step 1 AND for each terminus term (reduced to its root as applicable), showing the narrower "reference" term from which it was fetched with its accumulated information.

Example:

```xml
   <broader_term>
      <label>Building materials</label>
      <reference>
         <label>Timber</label>
         <occurrences self_or_subdiv="14"/>
      </reference>
   </broader_term>
   <broader_term>
      <label>Forest products</label>
      <reference>
         <label>Timber</label>
         <occurrences self_or_subdiv="14"/>
      </reference>
   </broader_term>
   <broader_term>
      <label>Lumber trade</label>
      <reference>
         <label>Timber</label>
         <occurrences self_or_subdiv="14"/>
      </reference>
   </broader_term>
```

3. Merge and organize term entries by matching labels, nesting terms that occur as both reference terms and broader terms under the broadest term level, and moving their combined reference terms under a single topic entry, including accumulated hierarchical information.
  - Run `step3_topic_merger.xsl` on the output of step 2, `{i}-2_bt_list.xml`.
  - The output `{i}-3_merged_topics.xml` includes a `<topic>` level for each broader term fetched in step 1 _that does not itself have another broader term thus far_ and for each terminus term, with all accumulated hierarchy information. _Note that duplicate entries occur at this stage._

Example:

```xml
   <topic>
      <label>Botany, Economic</label>
      <narrower_terms>
         <term>
            <label>Forest products</label>
            <occurrences self_or_subdiv="13"/>
            <narrower_terms>
               <term>
                  <label>Timber</label>
                  <occurrences self_or_subdiv="14"/>
                  <narrower_terms/>
               </term>
               <term>
                  <label>Wood</label>
                  <occurrences self_or_subdiv="13"/>
                  <narrower_terms/>
               </term>
            </narrower_terms>
         </term>
         <term>
            <label>Weeds</label>
            <occurrences self_or_subdiv="5"/>
            <narrower_terms>
               <term>
                  <label>Noxious weeds</label>
                  <occurrences self_or_subdiv="1"/>
                  <narrower_terms/>
               </term>
            </narrower_terms>
         </term>
      </narrower_terms>
   </topic>
```

4. De-duplicate the topic list generated in step 3.
- Run `step4_topic_deduper.xsl` on the output of step 3, `{i}-3_merged_topics.xml`.
- The output, `{i}-4_topic_list.xml`, includes the same information as the output of the previous step but with duplicate entries removed.

The topic list is then used to fetch the next level of broader terms. These four steps can be repeated until the chains of hierarchies from all original subject headings reach their terminus and no additional broader terms can be fetched. This will be indicated in the `<meta>` section when `<nextRound_lookup_count>` equals "0".

To run all four steps:  

```
java -jar ../saxon.jar -s:0-4_topic_list.xml -xsl:step1_bt_fetcher.xsl -o:x.xml iteration=1
java -jar ../saxon.jar -s:1-1_fetched_bts.xml -xsl:step2_bt_rearranger.xsl -o:x.xml iteration=1
java -jar ../saxon.jar -s:1-2_bt_list.xml -xsl:step3_topic_merger.xsl -o:x.xml iteration=1
java -jar ../saxon.jar -s:1-3_merged_topics.xml -xsl:step4_topic_deduper.xsl -o:x.xml iteration=1

java -jar ../saxon.jar -s:1-4_topic_list.xml -xsl:step1_bt_fetcher.xsl -o:x.xml iteration=2
java -jar ../saxon.jar -s:2-1_fetched_bts.xml -xsl:step2_bt_rearranger.xsl -o:x.xml iteration=2
java -jar ../saxon.jar -s:2-2_bt_list.xml -xsl:step3_topic_merger.xsl -o:x.xml iteration=2
java -jar ../saxon.jar -s:2-3_merged_topics.xml -xsl:step4_topic_deduper.xsl -o:x.xml iteration=2

[Continue to increment the iteration argument, along with the iteration number at the beginning of the source (-s:) filename.]
```

### Modeling

Steps 5 and 6 are situated at the end of the pipeline and are used to finalize the topic model. That said, they can be run at the end of any iteration; they do not require all original subjects to be traced to their terminus. 

5. Graph the relationships between the original subjects in the collection and the (current iteration) top-level terms. 
  - Run `step5_graph_topics.xsl` against the output of any iteration of step 4, `{i}-4_topic_list.xml`.  
  
```
java -jar ../saxon.jar -s:4-4_topic_list.xml -xsl:step5_graph_topics.xsl -o:x.xml iteration=example
```

  - The output, `{i}-5_topic_graph.xml` retains the overall structure and all top-level/terminus terms, but simplifies the entries to focus on the "original descendant" nodes.

Example:

```xml
<term label="Botany, Economic">
   <original_descendants>
      <term label="Forest products" occurrences="13"/>
      <term label="Timber" occurrences="14"/>
      <term label="Wood" occurrences="13"/>
      <term label="Lumber" occurrences="4"/>
      <term label="Wood waste" occurrences="3"/>
      <term label="Fuelwood" occurrences="1"/>
      <term label="Wood poles" occurrences="1"/>
      ...
      ...
      </original_descendants>
         <narrower_terms>
            <term label="Forest products" occurrences="13">
               <original_descendants>
                  <term label="Forest products" occurrences="13"/>
                  <term label="Timber" occurrences="14"/>
                  <term label="Wood" occurrences="13"/>
                  <term label="Lumber" occurrences="4"/>
                  <term label="Wood waste" occurrences="3"/>
                  <term label="Fuelwood" occurrences="1"/>
                  <term label="Wood poles" occurrences="1"/>
                  <term label="Plywood" occurrences="3"/>
               </original_descendants>
               ...
               ...
```

6. Calculate the combined occurrences of a term at any point in the the hierarchical chain along with its descendents to measure the overall prevalence of that topic in the collection. 
  - Run `step6_sum_topics.xsl` against the output of any iteration of step 5, `{i}-5_topic_graph.xml`.  
  
```
java -jar ../saxon.jar -s:example-5_topic_graph.xml -xsl:step6_sum_topics.xsl -o:x.xml iteration=example
```
  
  - The output of this step, `{i}-6_topic_model.xml`, lists the terms along each hierarchical chain, with each term's (1) number of original occurrences as itself; (2) number of "representative headings" that are descendants of that term; and (3) its "size" indicating the combined occurrences of itself and all of its representative headings. 
  - **This is considered the complete topic model (for that iteration).**

Example:

```xml
<term label="Botany, Economic" representative_headings="29" total_size="130">
   <term label="Forest products"
         occurrences="13"
         representative_headings="8"
         total_size="52">
      <term label="Timber"
            occurrences="14"
            representative_headings="1"
            total_size="14"/>
      <term label="Wood"
            occurrences="13"
            representative_headings="1"
            total_size="13"/>
      <term label="Wood products" representative_headings="5" total_size="12">
         <term label="Lumber"
               occurrences="4"
               representative_headings="1"
               total_size="4"/>
         <term label="Wood waste"
               occurrences="3"
               representative_headings="1"
               total_size="3"/>
         <term label="Fuelwood"
               occurrences="1"
               representative_headings="1"
               total_size="1"/>
         <term label="Wood poles"
               occurrences="1"
               representative_headings="1"
               total_size="1"/>
         <term label="Engineered wood" representative_headings="1" total_size="3">
            <term label="Laminated wood" representative_headings="1" total_size="3">
                <term label="Plywood"
                      occurrences="3"
                      representative_headings="1"
                      total_size="3"/>
                </term>
            </term>
         </term>
      </term>
...
...
```

### Analysis and Presentation

"Steps" 7-9 produce text files rather than XML for presenting the topic model. Steps 8 and 9 are run on the topic graph output from step 5; step 7 is run on the topic model output from step 6. These do not have to be run in sequence.

7. Generate a tabular (CSV) overview of the model. This presents two tables:
  - The first is all top-level, terminus-term topics that meet a given "threshold" or minimum number of representative-term occurrences as specified in the "threshold" parameter (default 10; 1 to return all top-level topics).
  - The second is "right-sized" topics, which refers to broader-term subject headings at any level of the hierarchical chains who have at least {lower} but not {upper} unique original subject heading descendants in the source collection. The "lower" and "upper" limits are specified in parameters (default lower=5; default upper=50). This is useful since many top terms, such as "Science," become so general or include so many narrower terms that they lose utility. 
  - Run `step7_present_topics.xsl` against the output step 6, `{i}-6_topic_model.xml`.
  
```
java -jar ../saxon.jar -s:example-6_topic_model.xml -xsl:step7_present_topics.xsl -o:x.xml iteration=example threshold=5 lower=10 upper=50
```

Example:

```text
Label,Number of Representative Subject Headings,Total Size of Concept

"Economics",227,859
"Physical sciences",243,835
"Occupations",172,821
"Handicraft",172,821
"Industrial arts",172,821
```

8. Generate a text (Markdown) list of top-level, terminus-term topics that meet a given "threshold" -- as in the first table in #7 -- along with their originally-occurring descendents nested beneath.
  - Run `step8_classify_topics.xsl` against the output of step 5, `{i}-5_topic_graph.xml`.  
  
```
java -jar ../saxon.jar -s:example-5_topic_graph.xml -xsl:step8_classify_topics.xsl -o:x.xml iteration=example threshold=10
```

Example: 

```md
- Biology, Economic (SH: 48; Size: 208)
    - Dogs (23)
    - Crops (16)
    - Timber (14)
    - Forest products (13)
    - Wood (13)
    - Fruit (12)
    - Poultry (12)
    - Livestock (11)
    - Vegetables (7)
    ...
...
```

9. Generate a text (Markdown) list of right-sized topics scoped by lower and upper limits -- as in the second table in #7 -- along with their originally-occurring descendents nested beneath.
  - Run `step9_reveal_topics.xsl` against the output of step 5, `{i}-5_topic_graph.xml`.  

```
java -jar ../saxon.jar -s:example-5_topic_graph.xml -xsl:step9_reveal_topics.xsl -o:x.xml iteration=example lower=3 upper=30
```

Example: 

```md
- Botany, Economic (SH: 29; Size: 130)
    - Crops (16)
    - Timber (14)
    - Forest products (13)
    - Wood (13)
    - Fruit (12)
    - Vegetables (7)
    ...
...
```

## Planned improvements

This pipeline is admittedly cumbersome. This is due in part to the author's limitations, but also to the processing demands of parsing the entirety of LCSH into complex structures. Future dedicated research into LCSH topic modeling is planned, which will include simplifying and streamlining the pipeline as well as improving commenting throughout. 

Future work will also add tools for extracting the initial set of subjects from MARCXML and potentially other metadata schemas.
