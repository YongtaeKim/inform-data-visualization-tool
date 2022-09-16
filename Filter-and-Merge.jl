"""
Quantitative Toolkit for inForm: Filter-Merge

Yongtae Kim
2021-01-20
ver 1.4

2020-12-09
added: Creates log files for stats and list.

2020-12-11
added: collect images of bad fields.

2020-12-14
added: creates merged slide csv file.

2020-12-15
fixed: 0 good field.

2021-01-11
command line arguments.

2021-01-12
fixed: read directory only.

2021-01-20
I suspect a bug in my code. I hope I can quickly fix this! 

2021-11-30
tiny fixes...

A bug found!
# ['171_Scan1_[12046,65513]_image_with_cell_seg_map.tif', '171_Scan1_[19495,62720]_image_with_cell_seg_map.tif', '171_Scan1_[21357,62022]_image_with_cell_seg_map.tif']
# -> flagged but not bad.
Fixed: Field with number of cell smaller than max_number went to bad field list without copy.

2021-04-13
A bug found when the apply_filter is false.
few small updates

"""

using DataFrames
using CSV
using Dates

# runs on a single slide folder
# takes about 200 seconds per slide.

"""
eg. 8 cells of cell with nucleus squre micro meter > 1000
LCNEC_cp (3)
1000, 8?
2000, 3? 64
2000, 2? 66
1500, 2? 68
1000, 1? 
"""



# Base filtering function
function FilterMerge(path_in; copy_images = false, apply_filter = false, make_merge = false, max_sq_um = 2000, max_number = 10, path_output_f = "", slash = "/")
    # When the path has to be created.
    if copy_images || make_merge
        slide_name = split(path_in, slash)[end-1]
        # makes directories.
        path_images = mkpath(join([path_output_f, slash, slide_name, slash, "bad_field_images"]))
    end

    # eg. 14_Scan1_[15818,49330]
    list_cellsegfiles = [f[1:findlast("]_", f)[1]] for f in readdir(path_in) if endswith(f, "]_cell_seg_data.txt")]
    num_field = 1

    list_badfield = Vector{String}()
    list_goodfield = Vector{String}()
    df_total = DataFrame()

    # if apply_filter
    for f in list_cellsegfiles
        print("Processing Fields: ", num_field, slash, length(list_cellsegfiles), "        \r")
        flush(stdout)

        df_f = DataFrame(CSV.File(join([path_in, f, "_cell_seg_data.txt"]), delim = '\t'))

        if apply_filter

            # Filtering rule!
            # total number of cells must be bigger than the max number.
            if size(df_f)[1] > max_number
                # sort and check
                # satisfies the bad field.
                if sort(df_f, [:"Nucleus Area (square microns)"], rev = true)[max_number, :]["Nucleus Area (square microns)"] > max_sq_um
                    # don't add to the merge DataFrame
                    # copy the images for reviewing.
                    if copy_images
                        if isfile(join([path_in, f, "_image_with_cell_seg_map.tif"]))
                            cp(join([path_in, f, "_image_with_cell_seg_map.tif"]), join([path_images, slash, f, "_image_with_cell_seg_map.tif"]))
                        elseif isfile(join([path_in, f, "_image_with_cell_seg_map.jpg"]))
                            cp(join([path_in, f, "_image_with_cell_seg_map.jpg"]), join([path_images, slash, f, "_image_with_cell_seg_map.jpg"]))
                        end
                    end
                    # record
                    push!(list_badfield, f)
                else
                    push!(list_goodfield, f)
                    if make_merge
                        # when merge
                        df_total = vcat(df_total, df_f)
                    end
                end
                # if the number of cells is smaller than the MAX_NUMBER, there is no need to sort. But is it a bad field??
                # -> No. Because it doesn't satisfy the condition anyway.
                # else
                # push!(list_badfield,f)
            end

        elseif !apply_filter
            # just concat
            if make_merge
                # when merge
                df_total = vcat(df_total, df_f)
            end
        end
        num_field += 1
    end
    # end

    if make_merge
        # Save the merged DataFrame
        open(join([path_output_f, slash, slide_name, slash, slide_name, "-Merged_cell_seg_data.csv"]), "w") do io
            CSV.write(io, df_total, delim = '\t')
            println("\nMerge file created.")
        end
        return (list_cellsegfiles, list_badfield, list_goodfield)
    elseif apply_filter
        return (list_cellsegfiles, list_badfield, list_goodfield)
    else
        return (list_cellsegfiles)
    end
end


function input(prompt::AbstractString = "")
    print(prompt)
    return chomp(readline())
end


function main()
    DATE_TIME = rsplit(replace(string(Dates.now()), ":" => "-"), ".")[1]
    SLASH = "\\" # "\\" for Windows "/" for Linux/macOS
    # auto detection
    if Sys.iswindows()
        SLASH = "\\"
    else
        SLASH = "/"
    end

    APPLY_FILTER = false
    COLLECT_IMAGES = true
    MAKE_MERGE_FILE = true

    FILTER_SQ_MICRON = "n/a"
    FILTER_NUM_CELL = "n/a"

    println("\nWelcome to Filter & Merge script for inForm Ouput Data!\n(author: Yongtae Kim)\n")

    if input("Filter out bad segmentation?. (yes or no): ") == "yes"
        APPLY_FILTER = true
        FILTER_SQ_MICRON = parse(Int, input("Enter minimum area of a cell to filter out.(sq micron). (eg. 1000): "))
        FILTER_NUM_CELL = parse(Int, input("Enter number of cells that matches the area to filter out. (eg. 2): "))
    end

    PATH_DATA = input("Enter path to the data. (eg. D:\\\\NCCLC\\\\batch\\\\all\\\\): ")
    PATH_OUTPUT = input("Enter path for the output files. (eg. D:\\\\programs\\\\output\\\\): ")
    PATH_OUTPUT_FILES = mkpath(join([PATH_OUTPUT, "_", DATE_TIME]))
    PATH_DATA = join([PATH_DATA, SLASH])


    # PATH_DATA = pwd()
    list_dir = [d for d in readdir(PATH_DATA, join = true) if isdir(d)]

    """
    Check and appends a slash to paths just in case.
    """
    for i = 1:length(list_dir)
        if !endswith(list_dir[i], "/") && !endswith(list_dir[i], "\\\\")
            if count("/", list_dir[i]) > 0
                list_dir[i] = join([list_dir[i], "/"])
            elseif count("\\\\", list_dir[i]) > 0
                list_dir[i] = join([list_dir[i], "\\\\"])
            end
        end
    end

    num_slide = length(list_dir)
    current_slide_num = 1

    # Also outputs stats for total.
    num_total_all = 0
    num_total_good = 0
    num_total_bad = 0

    file_num_list = open(join([PATH_OUTPUT_FILES, SLASH, "bad-field_number_list.txt"]), "w")
    file_num = open(join([PATH_OUTPUT_FILES, SLASH, "bad-field_number.txt"]), "w")

    write(file_num, "Filtering rule: Square micron - ", string(FILTER_SQ_MICRON), ",  Number of cells - ", string(FILTER_NUM_CELL), "\n")
    write(file_num_list, "Filtering rule: Square micron - ", string(FILTER_SQ_MICRON), ",  Number of cells - ", string(FILTER_NUM_CELL), "\n")

    for current_dir in list_dir
        println("\nSlide (", current_slide_num, SLASH, num_slide, "): ", current_dir)

        filter_result = FilterMerge(current_dir, apply_filter = APPLY_FILTER, copy_images = COLLECT_IMAGES, make_merge = MAKE_MERGE_FILE, max_sq_um = FILTER_SQ_MICRON, max_number = FILTER_NUM_CELL, path_output_f = PATH_OUTPUT_FILES, slash = SLASH)

        bad = length(filter_result[2])
        good = length(filter_result[3])
        total = length(filter_result[1])
        percent_f = round((length(filter_result[2]) / length(filter_result[1])) * 100; digits = 2)

        line = join(["\nSlide: ", current_dir, "\n", "- Bad: ", bad, " - Good: ", good, " - Total: ", total, "   =>  ", percent_f, "%", "\n"])
        list_field = join(filter_result[2], ", ")

        write(file_num, line)
        write(file_num_list, line, "List of the bad field(s):\n")
        write(file_num_list, list_field, "\n")

        # updates the numbers
        current_slide_num += 1
        num_total_all += total
        num_total_good += good
        num_total_bad += bad
    end

    percent_tot = round((num_total_bad / num_total_all) * 100; digits = 4)
    write(file_num, "Result: ", "- Bad: ", string(num_total_bad), " - Good: ", string(num_total_good), " - Total: ", string(num_total_all), "   =>  ", string(percent_tot), "%", "\n\n")
    write(file_num_list, "Result: ", "- Bad: ", string(num_total_bad), " - Good: ", string(num_total_good), " - Total: ", string(num_total_all), "   =>  ", string(percent_tot), "%", "\n\n")

    close(file_num)
    close(file_num_list)

    println("\n --- Finished !! --- \n\nOutput directory: ", PATH_OUTPUT_FILES, "\n")
    println("ALL slides: ", "- Bad: ", num_total_bad, " - Good: ", num_total_good, " - Total: ", num_total_all, "   =>  ", percent_tot, "%", "\n")

    return 0
end


main()
