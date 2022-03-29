# Microcontrollers Assembly Project
## for the EPFL course Microcontrollers [MICRO-210](https://isa.epfl.ch/imoniteur_ISAP/!itffichecours.htm?ww_i_matiere=1774892&ww_x_anneeAcad=2018-2019&ww_i_section=945244)
 
 
<!-- TABLE OF CONTENTS -->
## Table of Contents
 
* [About the Project](#about-the-project)
* [Important Modules](#Important Modules)
* [Contact](#contact)
 
<!-- ABOUT THE PROJECT -->
## About The Project
The project uses assembly on a STK-300 AVR Starter Kit to design a Music-Box that can play and save music while having a representation of the played notes as different colours on an LCD display.
 
 
<!-- Important Modules -->
## Important Modules
| **Name**              | **Arguments/Input**          | **Return/Output**       | **Description**                                                                                 |
|-----------------------|------------------------------|-------------------------|-------------------------------------------------------------------------------------------------|
| menu_main.asm         | user input                   | user interface (on LCD) | navigates through menu structure and calls other functions                                      |
| matrix.asm            | a0 (which button is pressed) | image on LED-matrix     | interprets input and uses them to create a light show on LED-matrix (with use of WS812B_driver) |
| playback.asm          | pdata to memorize            | data to be used         | manages saving to and restituting data from memory                                              |
| sound_driver.asm      | a0 (which button is pressed) | sound on buzzer         | takes care of playing tones and sounds on the buzzer                                            |
| memory_allocation.asm | -                            | -                       | memory allocations are centralized in this module                                               |

 
 
 
<!-- CONTACT -->
## Contact
Biselx Michael - michael.biselx@epfl.ch <br />
Samuel Bumann - samuel.bumann@epfl.ch
 
 
 
 
Project Link: [https://github.com/00niix/MicrocontrollersAssembly](https://github.com/00niix/MicrocontrollersAssembly)
 

