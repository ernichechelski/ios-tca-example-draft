import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testORFIlteringShouldResultWithItemsWhichSatisfiesAtLeastOneFilter() throws {
        
        let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        
        let factors = [
            FilterFactor<Int> { value in
                value.isMultiple(of: 4)
            },
            FilterFactor<Int> { value in
                value.isMultiple(of: 2)
            }
        ]
        
        let filtering = ORFiltering(
            source: items,
            factors: factors
        )
        
        XCTAssertEqual(filtering.result, [2, 4, 6, 8, 10])
    }
    
    func testANDFIlteringShouldResultWithItemsWhichSatisfiesAllFilters() throws {
        let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        
        let factors = [
            FilterFactor<Int> { value in
                value.isMultiple(of: 4)
            },
            FilterFactor<Int> { value in
                value.isMultiple(of: 2)
            }
        ]
        
        let filtering = ANDFiltering(
            source: items,
            factors: factors
        )
        
        XCTAssertEqual(filtering.result, [4,8])
    }
}
