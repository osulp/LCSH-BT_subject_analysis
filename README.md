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
    `java -jar ../saxon.jar -s:setup_fetch_EAD_subjects.xsl -xsl:setup_fetch_EAD_subjects.xsl -o:x.xml`
- The output `0_all_ead_lcsh.xml` should contain one `subject` entry containing the "root subject" for every LCSH term found in the source collection.
  - The `subject_list/subject/root_subject` XPATH are the key components of this file for continuing through the pipeline. The additional elements under `subject` may be used for validation and sanity checking.

Example:
```
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
    `java -jar ../saxon.jar -s:0_all_ead_lcsh.xml -xsl:step0_initialize_topics.xsl -o:x.xml`
- The output `0-4_topic_list.xml` gives a list of topics equating to the unique root subjects in the collection, with a count of the occurrences of each.

Example:  
```
   <topic>
      <label>Timber</label>
      <occurrences self_or_subdiv="14"/>
   </topic>
```

### Pipeline: Construct a topic model using LC Broader Terms

The pipeline consists of four steps run in sequence, then repeated over as many iterations as needed until all original subject headings are traced to their terminus. Terms retain information about their narrower terms, tracing back to the original subject headings, throughout the pipeline. Once a terminus term is identified, it is marked as such and copied through the rest of the pipeline without additional attempts to fetch its broader terms. Pipeline examples below are from the first iteration of processing, for brevity. Term entries become complex very quickly; a later-iteration example is available [as a separate XML file]().

1. Look up the LCSH entry in the LC SKOS/RDF XML file for each term in the current iteration's topic list; return its URI and broader terms.
  - Run `step1_bt_fetcher.xsl` on the output of either the Initialize Topics setup step or step 4 of the previous iteration, `{i}-4_topic_list.xml`.
  - The output `{i}-1_fetched_bts.xml` includes an `<LC_subject>` element for each topic term, showing its URI, label, number of occurrences in the original collection, its chain of narrower terms, and URIs and labels for each of its newly-fetched broader terms.

Example:

```
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
```
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
```
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



### Analysis and Presentation

## Planned improvements

This pipeline is admittedly cumbersome. This is due in part to the author's limitations, but also to the processing demands of parsing the entirety of LCSH. Future dedicated research into LCSH topic modeling is planned, which will include simplifying and streamlining the pipeline as well as improving commenting throughout. 

Future work will also add tools for extracting the initial set of subjects from MARCXML and potentially other metadata schemas.
