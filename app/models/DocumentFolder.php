<?php

class DocumentFolder extends Mad_Model_Base
{
    public function _initialize()
    {
        $this->hasMany('DocumentFiles', [
            'foreignKey' => 'folder_id',
            'order'      => 'LOWER(COALESCE(sort_title, title)) ASC'
        ]);
        $this->hasMany('Subfolders', [
            'className'  => 'DocumentFolder',
            'foreignKey' => 'parent_folder_id',
            'order'      => 'LOWER(COALESCE(sort_title, title)) ASC'
        ]);
        $this->belongsTo('ParentFolder', [
            'className'  => 'DocumentFolder',
            'foreignKey' => 'parent_folder_id'
        ]);
    }

    /**
     * Walk a slash-separated path of slugs starting from the root
     * "documents" folder. Returns the array of resolved folders.
     * Stops at the first slug that doesn't match a folder.
     */
    public static function resolvePath($path)
    {
        $slugs = array_filter(explode('/', trim($path, '/')));
        array_unshift($slugs, 'documents');

        $folders = [];
        $parentId = 0;

        foreach ($slugs as $slug) {
            $folder = self::findBySlugAndParent($slug, $parentId);
            if (!$folder) { break; }

            $folders[] = $folder;
            $parentId = $folder->id;
        }

        return $folders;
    }

    public static function findBySlugAndParent($slug, $parentFolderId)
    {
        return self::find('first', [
            'conditions' => 'LOWER(slug) = :slug AND parent_folder_id = :parent_folder_id'
        ], [
            ':slug' => strtolower($slug),
            ':parent_folder_id' => $parentFolderId
        ]);
    }

    public function findFile($filename)
    {
        // Direct query instead of the documentFiles association to avoid
        // loading all files in the folder just to find one by name.
        return DocumentFile::find('first', [
            'conditions' => 'LOWER(filename) = :filename AND folder_id = :folder_id'
        ], [
            ':filename' => strtolower($filename),
            ':folder_id' => $this->id
        ]);
    }

    public function path()
    {
        $slugs = [];
        $folder = $this;
        while ($folder) {
            array_unshift($slugs, $folder->slug);
            $folder = ($folder->parent_folder_id > 0)
                ? self::find($folder->parent_folder_id)
                : null;
        }
        return '/' . implode('/', $slugs) . '/';
    }
}
