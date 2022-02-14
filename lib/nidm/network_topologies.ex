defmodule Nidm.NetworkTopologies do

    # def clustered do
    #     %{ "1" => MapSet.new(["6", "13", "15", "16", "27", "35", "71", "75"]), "2" => MapSet.new(["3", "7", "32", "56", "68", "69", "73", "79"]),
    #     "3" => MapSet.new(["2", "7", "32", "51", "56", "69", "73", "78", "79"]), "4" => MapSet.new(["12", "14", "24", "29", "52", "63", "64", "70"]),
    #     "5" => MapSet.new(["19", "26", "28", "50", "52"]), "6" => MapSet.new(["1", "13", "15", "16", "27", "35", "71", "75"]),
    #     "7" => MapSet.new(["2", "3", "32", "51", "56", "69", "73", "78", "79"]), "8" => MapSet.new(["23", "34", "41", "46", "61", "68", "77"]),
    #     "9" => MapSet.new(["18", "30", "33", "34", "53", "70"]), "10" => MapSet.new(["24", "27", "71"]), "11" => MapSet.new(["16", "26", "37", "66"]),
    #     "12" => MapSet.new(["4", "14", "24", "29", "52", "59", "63", "64", "70"]), "13" => MapSet.new(["1", "6", "15", "27", "71", "72", "75"]),
    #     "14" => MapSet.new(["4", "12", "24", "29", "36", "58", "59", "64", "76"]), "15" => MapSet.new(["1", "6", "13", "27", "35", "72", "75"]),
    #     "16" => MapSet.new(["1", "6", "11", "19", "26", "28", "37", "50", "58", "76"]), "17" => MapSet.new(["18", "30", "33", "34", "53", "55", "74"]),
    #     "18" => MapSet.new(["9", "17", "30", "33", "34", "53", "67"]), "19" => MapSet.new(["5", "16", "26", "28", "37", "43", "50"]),
    #     "20" => MapSet.new(["25", "40", "43", "47", "57", "65", "80"]), "21" => MapSet.new(["23", "44", "45", "49", "54", "60"]),
    #     "22" => MapSet.new(["31", "49", "62"]), "23" => MapSet.new(["8", "21", "39", "41", "46", "61", "68", "77"]),
    #     "24" => MapSet.new(["4", "10", "12", "14", "29", "36", "59", "64"]), "25" => MapSet.new(["20", "29", "40", "42", "43", "57", "65", "80"]),
    #     "26" => MapSet.new(["5", "11", "16", "19", "28", "37", "50", "53"]), "27" => MapSet.new(["1", "6", "10", "13", "15", "35", "71"]),
    #     "28" => MapSet.new(["5", "16", "19", "26", "37", "50", "66"]), "29" => MapSet.new(["4", "12", "14", "24", "25", "36", "52", "59", "63"]),
    #     "30" => MapSet.new(["9", "17", "18", "33", "34", "53", "67"]), "31" => MapSet.new(["22", "44", "48", "55", "60", "62"]),
    #     "32" => MapSet.new(["2", "3", "7", "51", "65", "69", "73", "79"]), "33" => MapSet.new(["9", "17", "18", "30", "34", "53", "55", "74"]),
    #     "34" => MapSet.new(["8", "9", "17", "18", "30", "33", "46", "53"]), "35" => MapSet.new(["1", "6", "15", "27", "71", "72", "75"]),
    #     "36" => MapSet.new(["14", "24", "29", "59", "63", "64", "70"]), "37" => MapSet.new(["11", "16", "19", "26", "28", "50", "66"]),
    #     "38" => MapSet.new(["40", "51", "56", "78", "80"]), "39" => MapSet.new(["23", "41", "46", "61", "68", "77", "79"]),
    #     "40" => MapSet.new(["20", "25", "38", "42", "43", "57", "65"]), "41" => MapSet.new(["8", "23", "39", "46", "61", "68", "77", "78"]),
    #     "42" => MapSet.new(["25", "40", "43", "47", "57", "65", "80"]), "43" => MapSet.new(["19", "20", "25", "40", "42", "57", "65", "80"]),
    #     "44" => MapSet.new(["21", "31", "48", "49", "54", "60", "62"]), "45" => MapSet.new(["21", "48", "49", "54", "60", "61"]),
    #     "46" => MapSet.new(["8", "23", "34", "39", "41", "61", "77"]), "47" => MapSet.new(["20", "42", "57"]),
    #     "48" => MapSet.new(["31", "44", "45", "49", "54", "55", "60", "62"]), "49" => MapSet.new(["21", "22", "44", "45", "48", "54", "60", "62"]),
    #     "50" => MapSet.new(["5", "16", "19", "26", "28", "37", "60"]), "51" => MapSet.new(["3", "7", "32", "38", "56", "69", "78", "79"]),
    #     "52" => MapSet.new(["4", "5", "12", "29", "63", "64", "70"]), "53" => MapSet.new(["9", "17", "18", "26", "30", "33", "34", "74"]),
    #     "54" => MapSet.new(["21", "44", "45", "48", "49", "55", "60", "62"]), "55" => MapSet.new(["17", "31", "33", "48", "54", "62", "74"]),
    #     "56" => MapSet.new(["2", "3", "7", "38", "51", "69", "73", "78"]), "57" => MapSet.new(["20", "25", "40", "42", "43", "47", "80"]),
    #     "58" => MapSet.new(["14", "16", "76"]), "59" => MapSet.new(["12", "14", "24", "29", "36", "63", "64", "70"]),
    #     "60" => MapSet.new(["21", "31", "44", "45", "48", "49", "50", "54", "75"]), "61" => MapSet.new(["8", "23", "39", "41", "45", "46", "68", "77"]),
    #     "62" => MapSet.new(["22", "31", "44", "48", "49", "54", "55"]), "63" => MapSet.new(["4", "12", "29", "36", "52", "59", "64", "70"]),
    #     "64" => MapSet.new(["4", "12", "14", "24", "36", "52", "59", "63"]), "65" => MapSet.new(["20", "25", "32", "40", "42", "43", "80"]),
    #     "66" => MapSet.new(["11", "28", "37"]), "67" => MapSet.new(["18", "30", "74"]), "68" => MapSet.new(["2", "8", "23", "39", "41", "61", "77"]),
    #     "69" => MapSet.new(["2", "3", "7", "32", "51", "56", "73", "78", "79"]), "70" => MapSet.new(["4", "9", "12", "36", "52", "59", "63"]),
    #     "71" => MapSet.new(["1", "6", "10", "13", "27", "35", "75"]), "72" => MapSet.new(["13", "15", "35"]),
    #     "73" => MapSet.new(["2", "3", "7", "32", "56", "69", "77", "79"]), "74" => MapSet.new(["17", "33", "53", "55", "67"]),
    #     "75" => MapSet.new(["1", "6", "13", "15", "35", "60", "71"]), "76" => MapSet.new(["14", "16", "58"]),
    #     "77" => MapSet.new(["8", "23", "39", "41", "46", "61", "68", "73"]), "78" => MapSet.new(["3", "7", "38", "41", "51", "56", "69"]),
    #     "79" => MapSet.new(["2", "3", "7", "32", "39", "51", "69", "73"]), "80" => MapSet.new(["20", "25", "38", "42", "43", "57", "65"]) }
    # end

    def clustered do
        %{"1" =>  MapSet.new(["20", "32", "33", "51", "52", "53"]), "2" =>  MapSet.new(["4", "11", "23", "29", "34", "37"]),
        "3" =>  MapSet.new(["13", "15", "18", "35", "44"]), "4" =>  MapSet.new(["2", "11", "23", "34", "37", "59"]),
        "5" =>  MapSet.new(["27", "29", "40", "44", "46", "49"]), "6" =>  MapSet.new(["16", "21", "36", "38", "47", "48"]),
        "7" =>  MapSet.new(["10", "17", "22", "30", "37", "57"]), "8" =>  MapSet.new(["19", "23", "31", "34", "56", "59"]),
        "9" =>  MapSet.new(["19", "25", "39", "53", "58"]), "10" =>  MapSet.new(["7", "14", "17", "22", "30", "57"]),
        "11" =>  MapSet.new(["2", "4", "22", "23", "37", "59"]), "12" =>  MapSet.new(["19", "25", "39", "53", "58"]),
        "13" =>  MapSet.new(["3", "15", "18", "26", "28", "35"]), "14" =>  MapSet.new(["10", "24", "41", "45", "50", "55"]),
        "15" =>  MapSet.new(["3", "13", "18", "28", "35", "49"]), "16" =>  MapSet.new(["6", "21", "38", "47", "48", "54"]),
        "17" =>  MapSet.new(["7", "10", "22", "30", "32", "57"]), "18" =>  MapSet.new(["3", "13", "15", "26", "28", "35", "56"]),
        "19" =>  MapSet.new(["8", "9", "12", "31", "56", "58"]), "20" =>  MapSet.new(["1", "32", "33", "45", "51", "52"]),
        "21" =>  MapSet.new(["6", "16", "36", "39", "47", "54"]), "22" =>  MapSet.new(["7", "10", "11", "17", "30", "57"]),
        "23" =>  MapSet.new(["2", "4", "8", "11", "34", "59"]), "24" =>  MapSet.new(["14", "41", "43", "55", "60"]),
        "25" =>  MapSet.new(["9", "12", "33", "39", "53", "58"]), "26" =>  MapSet.new(["13", "18", "28", "51", "56"]),
        "27" =>  MapSet.new(["5", "29", "40", "42", "44", "49"]), "28" =>  MapSet.new(["13", "15", "18", "26", "35", "56"]),
        "29" =>  MapSet.new(["2", "5", "27", "40", "42", "46"]), "30" =>  MapSet.new(["7", "10", "17", "22", "52", "57"]),
        "31" =>  MapSet.new(["8", "19", "38", "48", "56"]), "32" =>  MapSet.new(["1", "17", "20", "33", "51", "52"]),
        "33" =>  MapSet.new(["1", "20", "25", "32", "51", "52"]), "34" =>  MapSet.new(["2", "4", "8", "23", "37", "59"]),
        "35" =>  MapSet.new(["3", "13", "15", "18", "28", "56"]), "36" =>  MapSet.new(["6", "21", "38", "47", "48", "54"]),
        "37" =>  MapSet.new(["2", "4", "7", "11", "34", "59"]), "38" =>  MapSet.new(["6", "16", "31", "36", "48", "54"]),
        "39" =>  MapSet.new(["9", "12", "21", "25", "53", "58"]), "40" =>  MapSet.new(["5", "27", "29", "42", "43", "46"]),
        "41" =>  MapSet.new(["14", "24", "43", "45", "50", "60"]), "42" =>  MapSet.new(["27", "29", "40", "44", "46", "49"]),
        "43" =>  MapSet.new(["24", "40", "41", "50", "55", "60"]), "44" =>  MapSet.new(["3", "5", "27", "42", "46", "49"]),
        "45" =>  MapSet.new(["14", "20", "41", "50", "55", "60"]), "46" =>  MapSet.new(["5", "29", "40", "42", "44", "49"]),
        "47" =>  MapSet.new(["6", "16", "21", "36", "54", "57"]), "48" =>  MapSet.new(["6", "16", "31", "36", "38", "54"]),
        "49" =>  MapSet.new(["5", "15", "27", "42", "44", "46"]), "50" =>  MapSet.new(["14", "41", "43", "45", "55", "60"]),
        "51" =>  MapSet.new(["1", "20", "26", "32", "33", "52"]), "52" =>  MapSet.new(["1", "20", "30", "32", "33", "51"]),
        "53" =>  MapSet.new(["1", "9", "12", "25", "39", "58"]), "54" =>  MapSet.new(["16", "21", "36", "38", "47", "48"]),
        "55" =>  MapSet.new(["14", "24", "43", "45", "50", "60"]), "56" =>  MapSet.new(["8", "18", "19", "26", "28", "31", "35"]),
        "57" =>  MapSet.new(["7", "10", "17", "22", "30", "47"]), "58" =>  MapSet.new(["9", "12", "19", "25", "39", "53"]),
        "59" =>  MapSet.new(["4", "8", "11", "23", "34", "37"]), "60" =>  MapSet.new(["24", "41", "43", "45", "50", "55"])}
    end

    # def unclustered do
    #     %{ "1" => MapSet.new(["6", "15", "16", "33", "40", "45", "64", "68"]), "2" => MapSet.new(["12", "16", "23", "33", "34", "36", "60", "76"]),
    #     "3" => MapSet.new(["4", "24", "39", "46", "55", "57", "58", "62"]), "4" => MapSet.new(["3", "11", "25", "35", "36", "38", "74", "78"]),
    #     "5" => MapSet.new(["13", "22", "25", "37", "44", "46", "57", "77"]), "6" => MapSet.new(["1", "14", "23", "32", "47", "71", "77", "79"]),
    #     "7" => MapSet.new(["17", "19", "30", "51", "52", "63", "67", "74"]), "8" => MapSet.new(["15", "16", "22", "41", "57", "61", "62", "71"]),
    #     "9" => MapSet.new(["12", "19", "27", "29", "50", "60", "63", "69"]), "10" => MapSet.new(["16", "23", "27", "44", "48", "49", "53", "71"]),
    #     "11" => MapSet.new(["4", "16", "55", "59", "71", "73", "75", "77"]), "12" => MapSet.new(["2", "9", "24", "25", "37", "41", "45", "66"]),
    #     "13" => MapSet.new(["5", "27", "32", "36", "70", "72", "75", "76"]), "14" => MapSet.new(["6", "27", "35", "53", "56", "66", "68", "76"]),
    #     "15" => MapSet.new(["1", "8", "23", "44", "53", "56", "69", "79"]), "16" => MapSet.new(["1", "2", "8", "10", "11", "50", "58", "80"]),
    #     "17" => MapSet.new(["7", "28", "29", "41", "47", "48", "70", "72"]), "18" => MapSet.new(["22", "25", "31", "37", "46", "55", "59", "78"]),
    #     "19" => MapSet.new(["7", "9", "28", "38", "42", "43", "49", "70"]), "20" => MapSet.new(["43", "48", "51", "52", "67", "72", "79"]),
    #     "21" => MapSet.new(["24", "33", "35", "36", "43", "56", "75", "79"]), "22" => MapSet.new(["5", "8", "18", "29", "35", "56", "65", "75"]),
    #     "23" => MapSet.new(["2", "6", "10", "15", "40", "50", "54", "80"]), "24" => MapSet.new(["3", "12", "21", "26", "30", "31", "42", "49"]),
    #     "25" => MapSet.new(["4", "5", "12", "18", "32", "60", "64", "76"]), "26" => MapSet.new(["24", "34", "38", "45", "60", "63", "66", "76"]),
    #     "27" => MapSet.new(["9", "10", "13", "14", "34", "38", "41", "61"]), "28" => MapSet.new(["17", "19", "30", "31", "39", "59", "63", "76"]),
    #     "29" => MapSet.new(["9", "17", "22", "51", "67", "71", "74", "80"]), "30" => MapSet.new(["7", "24", "28", "43", "48", "70", "72", "78"]),
    #     "31" => MapSet.new(["18", "24", "28", "43", "52", "56", "60", "72"]), "32" => MapSet.new(["6", "13", "25", "38", "57", "65", "69", "73"]),
    #     "33" => MapSet.new(["1", "2", "21", "48", "55", "58", "66"]), "34" => MapSet.new(["2", "26", "27", "67", "73", "74", "75", "80"]),
    #     "35" => MapSet.new(["4", "14", "21", "22", "37", "55", "57", "59"]), "36" => MapSet.new(["2", "4", "13", "21", "46", "57", "58", "73"]),
    #     "37" => MapSet.new(["5", "12", "18", "35", "38", "47", "75", "76"]), "38" => MapSet.new(["4", "19", "26", "27", "32", "37", "46", "58"]),
    #     "39" => MapSet.new(["3", "28", "41", "43", "51", "67", "73", "77"]), "40" => MapSet.new(["1", "23", "60", "62", "67", "71", "74", "79"]),
    #     "41" => MapSet.new(["8", "12", "17", "27", "39", "42", "49", "56"]), "42" => MapSet.new(["19", "24", "41", "51", "52", "60", "65", "72"]),
    #     "43" => MapSet.new(["19", "20", "21", "30", "31", "39", "47", "64"]), "44" => MapSet.new(["5", "10", "15", "50", "52", "54", "62", "80"]),
    #     "45" => MapSet.new(["1", "12", "26", "51", "53", "54", "61", "69"]), "46" => MapSet.new(["3", "5", "18", "36", "38", "65", "66", "68"]),
    #     "47" => MapSet.new(["6", "17", "37", "43", "54", "67", "74", "78"]), "48" => MapSet.new(["10", "17", "20", "30", "33", "50", "69", "74"]),
    #     "49" => MapSet.new(["10", "19", "24", "41", "60", "61", "74", "76"]), "50" => MapSet.new(["9", "16", "23", "44", "48", "53", "67", "71"]),
    #     "51" => MapSet.new(["7", "20", "29", "39", "42", "45", "54"]), "52" => MapSet.new(["7", "20", "31", "42", "44", "70", "77"]),
    #     "53" => MapSet.new(["10", "14", "15", "45", "50", "58", "62", "80"]), "54" => MapSet.new(["23", "44", "45", "47", "51", "65", "69", "71"]),
    #     "55" => MapSet.new(["3", "11", "18", "33", "35", "56", "64", "68"]), "56" => MapSet.new(["14", "15", "21", "22", "31", "41", "55", "78"]),
    #     "57" => MapSet.new(["3", "5", "8", "32", "35", "36", "64", "78"]), "58" => MapSet.new(["3", "16", "33", "36", "38", "53", "59", "61"]),
    #     "59" => MapSet.new(["11", "18", "28", "35", "58", "64", "65", "68"]), "60" => MapSet.new(["2", "9", "25", "26", "31", "40", "42", "49"]),
    #     "61" => MapSet.new(["8", "27", "45", "49", "58", "70", "73", "75"]), "62" => MapSet.new(["3", "8", "40", "44", "53", "65", "77"]),
    #     "63" => MapSet.new(["7", "9", "26", "28", "70", "72", "73", "78"]), "64" => MapSet.new(["1", "25", "43", "55", "57", "59", "77", "79"]),
    #     "65" => MapSet.new(["22", "32", "42", "46", "54", "59", "62", "78"]), "66" => MapSet.new(["12", "14", "26", "33", "46", "72", "73", "75"]),
    #     "67" => MapSet.new(["7", "20", "29", "34", "39", "40", "47", "50"]), "68" => MapSet.new(["1", "14", "46", "55", "59", "70", "77", "79"]),
    #     "69" => MapSet.new(["9", "15", "32", "45", "48", "54", "80"]), "70" => MapSet.new(["13", "17", "19", "30", "52", "61", "63", "68"]),
    #     "71" => MapSet.new(["6", "8", "10", "11", "29", "40", "50", "54"]), "72" => MapSet.new(["13", "17", "20", "30", "31", "42", "63", "66"]),
    #     "73" => MapSet.new(["11", "32", "34", "36", "39", "61", "63", "66"]), "74" => MapSet.new(["4", "7", "29", "34", "40", "47", "48", "49"]),
    #     "75" => MapSet.new(["11", "13", "21", "22", "34", "37", "61", "66"]), "76" => MapSet.new(["2", "13", "14", "25", "26", "28", "37", "49"]),
    #     "77" => MapSet.new(["5", "6", "11", "39", "52", "62", "64", "68"]), "78" => MapSet.new(["4", "18", "30", "47", "56", "57", "63", "65"]),
    #     "79" => MapSet.new(["6", "15", "20", "21", "40", "64", "68", "80"]), "80" => MapSet.new(["16", "23", "29", "34", "44", "53", "69", "79"]) }
    # end

    def unclustered do
        %{"1" =>  MapSet.new(["9", "11", "19", "24", "46", "52"]), "2" =>  MapSet.new(["15", "18", "38", "40", "49", "54"]),
        "3" =>  MapSet.new(["13", "36", "41", "53", "56"]), "4" =>  MapSet.new(["15", "35", "37", "39", "42", "55"]),
        "5" =>  MapSet.new(["11", "12", "24", "31", "34", "43"]), "6" =>  MapSet.new(["18", "26", "27", "34", "49", "60"]),
        "7" =>  MapSet.new(["11", "18", "23", "44", "50", "60"]), "8" =>  MapSet.new(["12", "14", "38", "42", "52", "58"]),
        "9" =>  MapSet.new(["1", "18", "26", "40", "45", "50"]), "10" =>  MapSet.new(["17", "20", "32", "37", "39", "44"]),
        "11" =>  MapSet.new(["1", "5", "7", "22", "44", "53"]), "12" =>  MapSet.new(["5", "8", "28", "29", "37", "46"]),
        "13" =>  MapSet.new(["3", "16", "17", "19", "20", "31"]), "14" =>  MapSet.new(["8", "26", "30", "50", "56", "57"]),
        "15" =>  MapSet.new(["2", "4", "16", "25", "37", "52"]), "16" =>  MapSet.new(["13", "15", "36", "39", "55", "58"]),
        "17" =>  MapSet.new(["10", "13", "19", "22", "42", "59"]), "18" =>  MapSet.new(["2", "6", "7", "9", "25", "51"]),
        "19" =>  MapSet.new(["1", "13", "17", "44", "50", "53"]), "20" =>  MapSet.new(["10", "13", "35", "45", "48", "58"]),
        "21" =>  MapSet.new(["33", "35", "37", "46", "47", "56"]), "22" =>  MapSet.new(["11", "17", "24", "33", "35", "59"]),
        "23" =>  MapSet.new(["7", "33", "38", "41", "43", "60"]), "24" =>  MapSet.new(["1", "5", "22", "43", "53", "55"]),
        "25" =>  MapSet.new(["15", "18", "27", "40", "52", "60"]), "26" =>  MapSet.new(["6", "9", "14", "42", "51", "58"]),
        "27" =>  MapSet.new(["6", "25", "36", "39", "41", "54"]), "28" =>  MapSet.new(["12", "36", "44", "48", "55", "59"]),
        "29" =>  MapSet.new(["12", "30", "34", "39", "53", "59"]), "30" =>  MapSet.new(["14", "29", "33", "36", "40", "48"]),
        "31" =>  MapSet.new(["5", "13", "47", "55", "58", "60"]), "32" =>  MapSet.new(["10", "41", "43", "45", "50", "58"]),
        "33" =>  MapSet.new(["21", "22", "23", "30", "49", "57"]), "34" =>  MapSet.new(["5", "6", "29", "46", "57", "59"]),
        "35" =>  MapSet.new(["4", "20", "21", "22", "45", "46"]), "36" =>  MapSet.new(["3", "16", "27", "28", "30", "57"]),
        "37" =>  MapSet.new(["4", "10", "12", "15", "21", "47"]), "38" =>  MapSet.new(["2", "8", "23", "43", "48", "49"]),
        "39" =>  MapSet.new(["4", "10", "16", "27", "29", "43"]), "40" =>  MapSet.new(["2", "9", "25", "30", "45", "46"]),
        "41" =>  MapSet.new(["3", "23", "27", "32", "44", "55"]), "42" =>  MapSet.new(["4", "8", "17", "26", "49", "51"]),
        "43" =>  MapSet.new(["5", "23", "24", "32", "38", "39"]), "44" =>  MapSet.new(["7", "10", "11", "19", "28", "41"]),
        "45" =>  MapSet.new(["9", "20", "32", "35", "40", "54"]), "46" =>  MapSet.new(["1", "12", "21", "34", "35", "40"]),
        "47" =>  MapSet.new(["21", "31", "37", "50", "51", "53"]), "48" =>  MapSet.new(["20", "28", "30", "38", "54", "59"]),
        "49" =>  MapSet.new(["2", "6", "33", "38", "42", "52"]), "50" =>  MapSet.new(["7", "9", "14", "19", "32", "47"]),
        "51" =>  MapSet.new(["18", "26", "42", "47", "54", "60"]), "52" =>  MapSet.new(["1", "8", "15", "25", "49", "54"]),
        "53" =>  MapSet.new(["3", "11", "19", "24", "29", "47"]), "54" =>  MapSet.new(["2", "27", "45", "48", "51", "52"]),
        "55" =>  MapSet.new(["4", "16", "24", "28", "31", "41"]), "56" =>  MapSet.new(["3", "14", "21", "57"]),
        "57" =>  MapSet.new(["14", "33", "34", "36", "56"]), "58" =>  MapSet.new(["8", "16", "20", "26", "31", "32"]),
        "59" =>  MapSet.new(["17", "22", "28", "29", "34", "48"]), "60" =>  MapSet.new(["6", "7", "23", "25", "31", "51"])}
    end

    def test do
        %{
            "1" => MapSet.new(["2", "8", "15"]),
            "2" => MapSet.new(["1", "3"]),
            "3" => MapSet.new(["2", "4"]),
            "4" => MapSet.new(["3", "5"]),
            "5" => MapSet.new(["4", "6"]),
            "6" => MapSet.new(["5", "7"]),
            "7" => MapSet.new(["6", "8"]),
            "8" => MapSet.new(["1", "7", "9"]),
            "9" => MapSet.new(["8", "10"]),
            "10" => MapSet.new(["9", "11"]),
            "11" => MapSet.new(["10", "12"]),
            "12" => MapSet.new(["11", "13"]),
            "13" => MapSet.new(["12", "14"]),
            "14" => MapSet.new(["13", "15"]),
            "15" => MapSet.new(["14", "1"])
        }
    end

    def big_test do
        %{
            "1" => MapSet.new(["2", "5"]),
            "2" => MapSet.new(["1", "3", "6"]),
            "3" => MapSet.new(["2", "4", "7"]),
            "4" => MapSet.new(["3", "8"]),
            "5" => MapSet.new(["1", "6", "9"]),
            "6" => MapSet.new(["2", "5", "7", "10"]),
            "7" => MapSet.new(["3", "6", "8", "11"]),
            "8" => MapSet.new(["4", "7", "12"]),
            "9" => MapSet.new(["5", "10", "13"]),
            "10" => MapSet.new(["6", "9", "11", "13"]),
            "11" => MapSet.new(["7", "10", "12", "13"]),
            "12" => MapSet.new(["8", "11", "13"]),
            "13" => MapSet.new(["9", "10", "11", "12", "14"]),
            "14" => MapSet.new(["13", "15", "28"]),
            "15" => MapSet.new(["14", "16", "17", "18", "19"]),
            "16" => MapSet.new(["15", "17", "20"]),
            "17" => MapSet.new(["15", "16", "18", "21"]),
            "18" => MapSet.new(["15", "17", "19", "22"]),
            "19" => MapSet.new(["15", "18", "23"]),
            "20" => MapSet.new(["16", "21", "24"]),
            "21" => MapSet.new(["17", "20", "22", "25"]),
            "22" => MapSet.new(["18", "21", "23", "26"]),
            "23" => MapSet.new(["19", "22", "27"]),
            "24" => MapSet.new(["20", "25"]),
            "25" => MapSet.new(["21", "24", "26"]),
            "26" => MapSet.new(["22", "25", "27"]),
            "27" => MapSet.new(["23", "26"]),
            "28" => MapSet.new(["14", "29", "30", "31", "32"]),
            "29" => MapSet.new(["28", "30", "33"]),
            "30" => MapSet.new(["28", "29", "31", "34"]),
            "31" => MapSet.new(["28", "30", "32", "35"]),
            "32" => MapSet.new(["28", "31", "36"]),
            "33" => MapSet.new(["29", "34", "37"]),
            "34" => MapSet.new(["30", "33", "35", "38"]),
            "35" => MapSet.new(["31", "34", "36", "39"]),
            "36" => MapSet.new(["32", "35", "40"]),
            "37" => MapSet.new(["33", "38"]),
            "38" => MapSet.new(["34", "37", "39"]),
            "39" => MapSet.new(["35", "38", "40"]),
            "40" => MapSet.new(["36", "39"])
        }
    end


end