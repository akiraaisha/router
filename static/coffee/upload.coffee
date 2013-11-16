$ ->
    UPLOAD_BLOCK_SIZE = 1024*1024*10
    logged_in = false
    uploading = false

    file_lists = []

    #music_template = _.template($('#music-template').html())

    if window.File and window.FileList and window.FileReader and window.Blob and window.Worker
        handleFileSelect = (evt) ->
            evt.stopPropagation()
            evt.preventDefault()

            $("#upload_files").hide()
            $("#uploading_files").show()
            #$(".container").hide()

            #if not logged_in
            #    alert "You need to login"
            #    return

            files = null
            if evt.target.files
                files = evt.target.files
            else
                files = evt.dataTransfer.files

            file_lists.push(files)
            file_index = 0
            startingByte = 0
            endingByte = 0

            uploadFile = (file) ->
                t =  if file.type then file.type else 'n/a'
                reader = new FileReader()
                tempfile = null

                xhrProvider = () ->
                    xhr = jQuery.ajaxSettings.xhr()
                    if xhr.upload
                        xhr.upload.addEventListener('progress', updateProgress, false)
                    return xhr

                updateProgress = (evt) ->
                    #console.log startingByte, file.size, evt.loaded, evt.total
                    $("#uploading_files").text("Uploading file #{file_index+1} of #{files.length} at #{(startingByte + (endingByte-startingByte)*evt.loaded/evt.total)/file.size*100}%")

                uploadNextFile = () ->
                    #console.log files, file_index
                    file_index++
                    if file_index < files.length
                        uploadFile(files[file_index])
                    else
                        file_lists.shift()
                        if file_lists.length > 0
                            file_index = 0
                            files = file_lists[0]
                            uploadFile(files[file_index])

                uploadFilePart = (data) ->
                    reader.onload = (evt) ->
                        content = evt.target.result.slice evt.target.result.indexOf("base64,")+7
                        bin = atob content

                        $.ajax
                            type: 'POST',
                            dataType: 'json',
                            url: '/api/file/upload_html5_slice',
                            data:
                                "tempfile": tempfile,
                                "name": file.name,
                                "content": content,
                                "start": startingByte,
                                "size": file.size,
                            xhr: xhrProvider,
                            success: uploadFilePart

                     if data["result"] == "success"
                        $("#uploading_files").text("File uploading successed!")
                        $('#list').append("<li><strong>#{ file.name }</strong> (#{ t }) - #{ file.size } bytes</li>")

                        $("#list li").slice(0, -10).slideUp () ->
                            $("#list li").slice(0, -10).remove()

                        uploadNextFile()
                        return

                    else if data["result"] == "uploading"
                        tempfile = data["tempfile"]
                        startingByte = data["uploaded_size"]
                        endingByte = if startingByte + UPLOAD_BLOCK_SIZE < file.size then startingByte + UPLOAD_BLOCK_SIZE else file.size

                    else if data["result"] == "error"
                        uploadFile(files[file_index])
                        return

                    if file.slice
                        blob = file.slice startingByte, endingByte
                    else if file.webkitSlice
                        blob = file.webkitSlice startingByte, endingByte
                    else if file.mozSlice
                        blob = file.mozSlice startingByte, endingByte
                    else
                        alert "Not support slice API"
                    reader.readAsDataURL(blob)

                uploadFilePart({"result": "not found"})

            if file_lists.length == 1
                uploadFile(files[file_index])


        handleDragEnter = (evt) ->
            #if logged_in
            #    $(".container").show()
            #else
            #    alert "You need to login"

        handleDragLeave = (evt) ->
            #$(".container").hide()

        handleDragOver = (evt) ->
            evt.stopPropagation()
            evt.preventDefault()

        wrapper = document.getElementById('upload')
        if wrapper
            wrapper.addEventListener('dragenter', handleDragEnter, false)
            wrapper.addEventListener('dragover', handleDragOver, false)
            wrapper.addEventListener('drop', handleFileSelect, false)
        container = document.getElementsByClassName("container")[0]
        container.addEventListener('dragleave', handleDragLeave, false)

    else
        $('section').text('Require Chrome, Firefox, Safari 6 or IE 10')
