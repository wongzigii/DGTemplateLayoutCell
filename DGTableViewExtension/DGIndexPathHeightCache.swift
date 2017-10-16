//
//  DGIndexPathHeightCache.swift
//
//  Created by zhaodg on 11/25/15.
//  Copyright © 2015 zhaodg. All rights reserved.
//

import UIKit

// MARK: - DGIndexPathHeightCache
class DGIndexPathHeightCache {

    private var heights: [[CGFloat]] = []

    // Enable automatically if you're using index path driven height cache. Default is true
    internal var automaticallyInvalidateEnabled: Bool = true

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(DGIndexPathHeightCache.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    // MARK: - public
    subscript(indexPath: IndexPath) -> CGFloat? {
        get {
            if indexPath.section < heights.count && indexPath.row < heights[indexPath.section].count {
                return heights[indexPath.section][indexPath.row]
            }
            return nil
        }
        set {
            self.buildIndexPathIfNeeded(indexPath: indexPath)
            heights[indexPath.section][indexPath.row] = newValue!
        }
    }

    internal func invalidateHeightAtIndexPath(indexPath: IndexPath) {
        self[indexPath] = -1
    }

    internal func invalidateAllHeightCache() {
        self.heights.removeAll()
    }

    internal func existsIndexPath(indexPath: IndexPath) -> Bool {
        let n: CGFloat = -0.000001
        if let indexPath = self[indexPath], indexPath > n {
            return true
        }
        return false
    }

    internal func insertSections(sections: IndexSet) {
        for (index, _) in sections.enumerated() {
            self.buildSectionsIfNeeded(targetSection: index)
            self.heights.insert([], at: index)
        }
    }

    internal func deleteSections(sections: IndexSet) {
        for (index, _) in sections.enumerated() {
            self.buildSectionsIfNeeded(targetSection: index)
            self.heights.remove(at: index)
        }
    }

    internal func reloadSections(sections: IndexSet) {
        for (index, _) in sections.enumerated() {
            self.buildSectionsIfNeeded(targetSection: index)
            self.heights[index] = []
        }
    }

    internal func moveSection(section: Int, toSection newSection: Int) {
        self.buildSectionsIfNeeded(targetSection: section)
        self.buildSectionsIfNeeded(targetSection: newSection)
        swap(&self.heights[section], &self.heights[newSection])
    }

    internal func insertRowsAtIndexPaths(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            self.buildIndexPathIfNeeded(indexPath: indexPath)
            self.heights[indexPath.section].insert(-1, at: indexPath.row)
        }
    }

    internal func deleteRowsAtIndexPaths(indexPaths: [IndexPath]) {
        let indexPathSorted = indexPaths.sorted { $0.section > $1.section || $0.row > $1.row }
        for indexPath in indexPathSorted {
            self.buildIndexPathIfNeeded(indexPath: indexPath)
            self.heights[indexPath.section].remove(at: indexPath.row)
        }
    }

    internal func reloadRowsAtIndexPaths(indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            self.buildIndexPathIfNeeded(indexPath: indexPath)
            self.invalidateHeightAtIndexPath(indexPath: indexPath)
        }
    }

    internal func moveRowAtIndexPath(indexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        self.buildIndexPathIfNeeded(indexPath: indexPath)
        self.buildIndexPathIfNeeded(indexPath: newIndexPath)
        swap(&self.heights[indexPath.section][indexPath.row], &self.heights[indexPath.section][indexPath.row])
    }

    // MARK: - private 
    private func buildSectionsIfNeeded(targetSection: Int) {
        if targetSection >= heights.count {
            for _ in heights.count...targetSection {
                self.heights.append([])
            }
        }
    }

    private func buildRowsIfNeeded(targetRow: Int, existSextion: Int) {
        if existSextion < heights.count && targetRow >= heights[existSextion].count {
            for _ in heights[existSextion].count...targetRow {
                self.heights[existSextion].append(-1)
            }
        }
    }

    private func buildIndexPathIfNeeded(indexPath: IndexPath) {
        self.buildSectionsIfNeeded(targetSection: indexPath.section)
        self.buildRowsIfNeeded(targetRow: indexPath.row, existSextion: indexPath.section)
    }

    @objc private func deviceOrientationDidChange() {
        self.invalidateAllHeightCache()
    }
}

// MARK: - UITableView Extension
extension UITableView {

    private struct AssociatedKey {
        static var DGIndexPathHeightCache = "DGIndexPathHeightCache"
    }

    /// Height cache by index path. Generally, you don't need to use it directly.
    internal var dg_indexPathHeightCache: DGIndexPathHeightCache {
        if let value: DGIndexPathHeightCache = objc_getAssociatedObject(self, &AssociatedKey.DGIndexPathHeightCache) as? DGIndexPathHeightCache {
            return value
        } else {
            let cache: DGIndexPathHeightCache = DGIndexPathHeightCache()
            objc_setAssociatedObject(self, &AssociatedKey.DGIndexPathHeightCache, cache, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return cache
        }
    }
}
