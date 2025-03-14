# Waze Pull Request
<!-- Instructions -->
<!--   Be sure to tag to the head of the main branch with the version after the Pull Request is merged. -->
<!--  -->
|                              |            |
|------------------------------|------------|
| __Proposed Release Version__ | 1.0.0      |
| __Proposed Release Date__    | 2025-00-00 |
| __Release Type__             | Fast Track |
| __Risk Type__                | Low        |
| __Expected Downtime__        | None       |

## Summary
<!-- Instructions -->
<!--   Provide a summary of the change to be implemented, references to Jira/Confluence pages for background information, etc. -->
<!--   Provide benefits of implementing the change -->
- Summary of changes

## Work Items
<!-- Instructions -->
<!-- Provide a link to the parent, child and other related Jira stories -->
<!-- Pull Requests without links will not be approved -->
- Parent: [SDC-0000: Parent Story](https://securedatacommons.atlassian.net/browse/SDC-0000)
  - Child: [SDC-0000: Child Story](https://securedatacommons.atlassian.net/browse/SDC-0000)
- Related: [DESK-0000: Related Story](https://securedatacommons.atlassian.net/browse/DESK-0000)

## Users to Notify
<!-- Instructions -->
<!--   Provide a list or group of users affected by the change -->
- SDC User Community
- All Waze Researchers
- Acme Data Provider

## Cost Impacts
<!-- Instructions -->
<!--   Provide details on system cost impacts -->
- System cost impacts

## User Guide Updates
<!-- Instructions -->
<!--   Provide details on what training materials have been updated/created, include a link -->
- [RT Guide: Researchers' User Guide](https://securedatacommons.atlassian.net/wiki/spaces/DESK/pages/2223964161/)
  - [Chapter 1, Introduction and Document Overview](https://securedatacommons.atlassian.net/wiki/spaces/DESK/pages/2224586753/)
- [DP Guide: Data Providers' User Guide](https://securedatacommons.atlassian.net/wiki/spaces/DESK/pages/1376780433/)
  - [Chapter 1, Introduction and Document Overview](https://securedatacommons.atlassian.net/wiki/spaces/DESK/pages/2253586439/)

## Process, Procedure and Work Instruction
- [Process: Development](https://securedatacommons.atlassian.net/wiki/spaces/DO/pages/1332379871)
- [Documentation](/doc/index.md)

## Release Type Classification and Justification
<!-- Instructions -->
<!--   Provide details on the Release Type -->
<!--   Release Type -->
<!--     Major: Architectural or significant functionality changes -->
<!--     Minor: Routine minor enhancements to existing functionality -->
<!--     Fast Track: Functionality enhancements with limited risk -->
<!--     Hot Fix: Solutions for defects impacting expected user functionality -->
- Release Type: Fast Track

## Risk Level Classification and Justification
<!-- Instructions -->
<!--   Provide details on the Risk Level and Risk Level Justification -->
<!--   Risk Levels: -->
<!--     0-2: Low -->
<!--     3-4: Medium -->
<!--     5-7: High -->
- Risk Level: Low (0)

### Risk Level Justification
| Risk                                                                           | Level |
|:------------------------------------------------------------------------------ |:-----:|
| Are there any modifications to system configuration?                           |   0   |
| Are there any additions or modifications to security settings?                 |   0   |
| Is a new workflow introduced or an existing workflow altered significantly?    |   0   |
| Is user behavior affected as a result of this change?                          |   0   |
| Is service outage required to deploy this change?                              |   0   |
| Are new system inter-dependencies introduced?                                  |   0   |
| Has this type of change been attempted before successfully? (Yes = 0, No = 1)  |   0   |

## Plans
<!-- Instructions -->
<!--   Provide a link to the plans directory of the repo -->
<!--   After deployment, check off the items from the Test Plan. Record the results as comments on this pull request. -->
- [Plans](/plans/)

## DevOps Checklist
- [ ] **Pull Request Title**  
The pull request title should be in accordance with the following naming convention:  
_{PR Title} (SDC-{parent} SDC-{child})_  
For example:
  - Waze: Fix Ingest Issue (SDC-1234 SDC-5678)
  - Waze: Fix Deduplication Issue (SDC-9012 SDC-3456)

- [ ] **Avoid Hardcoding**  
Any string literal values that are likely to change should not be hardcoded and instead put into a config file or something like the AWS Systems Manager Parameter Store.

- [ ] **Self-Documenting Code**  
Code should include comments for clarity, but should also be self-documenting. This means using meaningful function and variable names to help indicate why/when the function or variable is used.

- [ ] **Docstrings and Type Hints**  
In Python scripts:
  - Include docstrings: [Wikipedia: Docstring ∬Python](https://en.wikipedia.org/wiki/Docstring#Python)
    ```python
    def my_function(arg1: Any, arg2: Any) -> Any:
    """This function does something.

    Args:
      arg1: The first argument.
      arg2: The second argument.

    Returns:
      The result of doing something.
    """
    # Do something with arg1 and arg2.
    return result
    ```
  - Use type hints: [Python Support for Type Hints](https://docs.python.org/3/library/typing.html)

- [ ] **Logging and Debugging**  
Code should have an appropriate amount of logging to be able to troubleshoot foreseeable problems.

- [ ] **Error Handling**  
Exceptions should be logged unless they are an expected, valid use case. Exceptions should NOT be swallowed unless they are recoverable.

- [ ] **Security**  
Are secrets being utilized in the code? If so, are they handled properly and not logged to output or exposed. Does this change require a Security Impact Analysis (SIA)?  
Check for the following:
  - Passwords
  - Private Tokens/Keys
  - Account Numbers
  - Usernames
  - Email Addresses

## Security Impact Analysis (SIA)
  <!-- Instructions -->
  <!--   Review the SIA WI -->
  - [ ] I have reviewed the [Performing a Security Impact Analysis (SIA)](https://securedatacommons.atlassian.net/wiki/spaces/DO/pages/2642935856) work instructions.
  <!--   Does this change require a SIA? -->
  - This change __DOES/DOES NOT__ require a SIA

<!--   If not required, delete the following SIA template 
### Change Information
Description of System Change (This must be a detailed description that includes the Drivers for the change)

### Technical Representative Information
If a technical representative of the ISSO is performing this assessment on behalf of the ISSO, please provide your contact information.
- Representative performing the SIA: 
- Title of Representative performing the SIA: 

### Trigger Actions and Events Evaluation
Directions: Please complete the following by indicating Y/N if a particular security event occurs and entering a description of the summary of security impacts/technical overview/risks identified. Highlight anything where a possible significant change is detected. The ARS Controls impacted is not all-inclusive.  
Note: this is not all-inclusive.

### Security Impact Analysis (SIA) Checklist
- Mission/Business requirements
  - [ ] New Users or New User Roles Added
  - [ ] Change in data collection, storage, sharing  
  - [ ] Cessation of mission or function.  

- Policy/Standards
  - [ ] New revisions of ARS and CMS policy; or Issue or Update of NIST documents  

- Laws, Regulations, Directives
  - [ ] New or Changed  

- System boundary
  - [ ] Interconnections and New connection to FISMA system or Service  
  - [ ] Architecture, Topology, Port/Protocol/Service change  
  - [ ] New processing location(s)  

- System boundary (environment)
  - [ ] Change or Addition of Hosting Infrastructure or Site    

- Security components
  - [ ] Identification, Authentication, Authorization, New methods for authentication and/or 
  - [ ] Security Controls – Change in implementation standard or status  

- User Interface
  - [ ] Updates to GUI including addition of new pages, new inputs

- New or Updated Hardware
  - [ ] Servers, Communication Devices

- New or Updated Operating System
  - [ ] Change in Operating System

- New or Updated Security Software
  - [ ] New Security Software or Perimeter Security Change

- Support Software
  - [ ] New Support Software

- Vendor Patches
  - [ ] Software, Servers

- Vulnerability (New or Existing)
  - [ ] Attacks Developed
  - [ ] Attacks Succeed Elsewhere
  - [ ] Found (No Attacks Known)
-->

## Meets Definition of Ready?
- [ ] Yes